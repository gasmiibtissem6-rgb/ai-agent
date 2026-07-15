from pathlib import Path
from typing import Any

import chromadb
from pypdf import PdfReader
from sentence_transformers import SentenceTransformer

from core.logger import logger
from core.reranker import rerank_passages
from database.contracts import get_contract_by_id


VECTOR_DB_PATH = "vector_store"
COLLECTION_NAME = "contracts"

EMBEDDING_MODEL_NAME = (
    "sentence-transformers/"
    "paraphrase-multilingual-MiniLM-L12-v2"
)


class ContractRAGService:
    """
    Service RAG local pour indexer et rechercher
    dans les contrats enregistrés.
    """

    def __init__(self) -> None:
        self.client = chromadb.PersistentClient(
            path=VECTOR_DB_PATH,
        )

        self.collection = self.client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"hnsw:space": "cosine"},
        )

        logger.info(
            "Chargement du modèle d'embeddings : %s",
            EMBEDDING_MODEL_NAME,
        )

        self.embedding_model = SentenceTransformer(
            EMBEDDING_MODEL_NAME
        )

    @staticmethod
    def chunk_text(
        text: str,
        chunk_size: int = 800,
        overlap: int = 150,
    ) -> list[str]:
        """
        Découpe un texte en morceaux avec chevauchement.
        """

        cleaned_text = " ".join(text.split())

        if not cleaned_text:
            return []

        chunks: list[str] = []
        start = 0

        while start < len(cleaned_text):
            end = start + chunk_size
            chunk = cleaned_text[start:end].strip()

            if chunk:
                chunks.append(chunk)

            if end >= len(cleaned_text):
                break

            start = end - overlap

        return chunks

    @staticmethod
    def extract_pdf_text(
        pdf_path: str | None,
    ) -> str:
        """
        Extrait le texte d'un fichier PDF.
        """

        if not pdf_path:
            return ""

        path = Path(pdf_path)

        if not path.exists():
            logger.warning(
                "PDF introuvable pour le RAG : %s",
                pdf_path,
            )
            return ""

        try:
            reader = PdfReader(str(path))
            pages_text: list[str] = []

            for page in reader.pages:
                page_text = page.extract_text() or ""

                if page_text.strip():
                    pages_text.append(page_text)

            return "\n".join(pages_text)

        except Exception:
            logger.exception(
                "Erreur pendant l'extraction du PDF : %s",
                pdf_path,
            )
            return ""

    @staticmethod
    def contract_metadata_text(
        contract: Any,
    ) -> str:
        """
        Transforme les données structurées du contrat en texte.
        """

        return f"""
Identifiant du contrat : {contract.id}
Référence : {contract.reference or "Non précisée"}
Type de contrat : {contract.contract_type or "Non précisé"}

Prestataire :
Nom : {contract.provider_name or "Non précisé"}
Email : {contract.provider_email or "Non précisé"}
Téléphone : {contract.provider_phone or "Non précisé"}
Adresse : {contract.provider_address or "Non précisée"}

Client :
Nom : {contract.client_name or "Non précisé"}
Email : {contract.client_email or "Non précisé"}
Téléphone : {contract.client_phone or "Non précisé"}
Adresse : {contract.client_address or "Non précisée"}

Durée : {contract.duration or "Non précisée"}
Prix : {contract.price or "Non précisé"}
Mode de paiement : {contract.payment_method or "Non précisé"}
Lieu : {contract.place or "Non précisé"}
Date de création : {contract.created_at}
""".strip()

    def index_contract(
        self,
        contract_id: int,
    ) -> dict:
        """
        Indexe un contrat enregistré dans ChromaDB.
        """

        if not isinstance(contract_id, int):
            return {
                "error": "contract_id doit être un entier."
            }

        contract = get_contract_by_id(contract_id)

        if contract is None:
            return {
                "error": "Contrat introuvable."
            }

        metadata_text = self.contract_metadata_text(
            contract
        )

        pdf_text = self.extract_pdf_text(
            contract.pdf_path
        )

        complete_text = (
            metadata_text
            + "\n\nContenu du document PDF :\n"
            + pdf_text
        ).strip()

        chunks = self.chunk_text(
            complete_text
        )

        if not chunks:
            return {
                "error": (
                    "Aucun contenu exploitable n'a été trouvé "
                    "pour ce contrat."
                )
            }

        logger.info(
            "Création des embeddings RAG | contract_id=%s | chunks=%s",
            contract_id,
            len(chunks),
        )

        embeddings = self.embedding_model.encode(
            chunks,
            normalize_embeddings=True,
        ).tolist()

        try:
            self.collection.delete(
                where={"contract_id": contract_id}
            )
        except Exception:
            logger.warning(
                "Aucune ancienne indexation à supprimer "
                "pour contract_id=%s",
                contract_id,
            )

        ids = [
            f"contract-{contract_id}-chunk-{index}"
            for index in range(len(chunks))
        ]

        metadatas = [
            {
                "contract_id": contract_id,
                "contract_type": (
                    contract.contract_type or ""
                ),
                "client_name": (
                    contract.client_name or ""
                ),
                "provider_name": (
                    contract.provider_name or ""
                ),
                "source": (
                    contract.pdf_path or "database"
                ),
                "chunk_index": index,
            }
            for index in range(len(chunks))
        ]

        self.collection.upsert(
            ids=ids,
            documents=chunks,
            embeddings=embeddings,
            metadatas=metadatas,
        )

        logger.info(
            "Contrat indexé dans le RAG | contract_id=%s",
            contract_id,
        )

        return {
            "status": "indexed",
            "contract_id": contract_id,
            "chunks_indexed": len(chunks),
            "collection": COLLECTION_NAME,
        }

    def search(
        self,
        query: str,
        n_results: int = 8,
        contract_id: int | None = None,
        max_distance: float = 0.70,
        top_k: int = 3,
    ) -> dict:
        """
        Recherche les passages les plus proches
        sémantiquement de la question utilisateur.

        Étapes :
        1. Recherche vectorielle dans ChromaDB.
        2. Filtrage selon max_distance.
        3. Re-ranking avec un CrossEncoder.
        4. Conservation des top_k meilleurs passages.
        """

        if not query or not query.strip():
            return {
                "error": "La question de recherche est vide."
            }

        if not isinstance(n_results, int):
            return {
                "error": "n_results doit être un entier."
            }

        if not isinstance(top_k, int):
            return {
                "error": "top_k doit être un entier."
            }

        if not isinstance(max_distance, (int, float)):
            return {
                "error": "max_distance doit être un nombre."
            }

        if max_distance < 0:
            return {
                "error": (
                    "max_distance doit être supérieur "
                    "ou égal à 0."
                )
            }

        safe_n_results = max(
            1,
            min(n_results, 20),
        )

        safe_top_k = max(
            1,
            min(top_k, safe_n_results),
        )

        query_embedding = self.embedding_model.encode(
            [query],
            normalize_embeddings=True,
        ).tolist()

        query_arguments: dict[str, Any] = {
            "query_embeddings": query_embedding,
            "n_results": safe_n_results,
            "include": [
                "documents",
                "metadatas",
                "distances",
            ],
        }

        if contract_id is not None:
            if not isinstance(contract_id, int):
                return {
                    "error": (
                        "contract_id doit être un entier."
                    )
                }

            query_arguments["where"] = {
                "contract_id": contract_id
            }

        try:
            results = self.collection.query(
                **query_arguments
            )

        except Exception:
            logger.exception(
                "Erreur pendant la recherche RAG"
            )

            return {
                "error": (
                    "La recherche dans la base vectorielle "
                    "a échoué."
                )
            }

        documents = (
            results.get("documents", [[]])[0]
            if results.get("documents")
            else []
        )

        metadatas = (
            results.get("metadatas", [[]])[0]
            if results.get("metadatas")
            else []
        )

        distances = (
            results.get("distances", [[]])[0]
            if results.get("distances")
            else []
        )

        passages: list[dict[str, Any]] = []

        for index, document in enumerate(documents):
            metadata = (
                metadatas[index]
                if index < len(metadatas)
                else {}
            )

            distance = (
                distances[index]
                if index < len(distances)
                else None
            )

            if (
                distance is not None
                and distance > max_distance
            ):
                logger.info(
                    "Passage RAG ignoré | distance=%.4f | seuil=%.4f",
                    distance,
                    max_distance,
                )
                continue

            passages.append({
                "text": document,
                "metadata": metadata,
                "distance": distance,
            })

        if not passages:
            return {
                "query": query,
                "contract_id": contract_id,
                "max_distance": max_distance,
                "requested_results": safe_n_results,
                "top_k": safe_top_k,
                "count_before_reranking": 0,
                "count": 0,
                "passages": [],
                "message": (
                    "Aucun passage suffisamment pertinent "
                    "n'a été trouvé."
                ),
            }

        reranked_passages = rerank_passages(
            query=query,
            passages=passages,
            top_k=safe_top_k,
        )

        logger.info(
            "Re-ranking terminé | candidats=%s | retenus=%s",
            len(passages),
            len(reranked_passages),
        )

        return {
            "query": query,
            "contract_id": contract_id,
            "max_distance": max_distance,
            "requested_results": safe_n_results,
            "top_k": safe_top_k,
            "count_before_reranking": len(passages),
            "count": len(reranked_passages),
            "passages": reranked_passages,
        }


RAG_SERVICE = ContractRAGService()


def index_contract_in_rag(
    contract_id: int,
) -> dict:
    return RAG_SERVICE.index_contract(
        contract_id=contract_id,
    )


def search_contract_knowledge(
    query: str,
    n_results: int = 8,
    contract_id: int | None = None,
    max_distance: float = 0.70,
    top_k: int = 3,
) -> dict:
    return RAG_SERVICE.search(
        query=query,
        n_results=n_results,
        contract_id=contract_id,
        max_distance=max_distance,
        top_k=top_k,
    )