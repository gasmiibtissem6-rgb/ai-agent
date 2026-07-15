from typing import Any

from sentence_transformers import CrossEncoder

from core.logger import logger


RERANKER_MODEL_NAME = (
    "cross-encoder/"
    "mmarco-mMiniLMv2-L12-H384-v1"
)


class ContractReranker:
    """
    Reclasse les passages récupérés par ChromaDB
    selon leur pertinence réelle par rapport à la question.
    """

    def __init__(self) -> None:
        logger.info(
            "Chargement du modèle de re-ranking : %s",
            RERANKER_MODEL_NAME,
        )

        self.model = CrossEncoder(
            RERANKER_MODEL_NAME
        )

    def rerank(
        self,
        query: str,
        passages: list[dict[str, Any]],
        top_k: int = 3,
    ) -> list[dict[str, Any]]:
        """
        Retourne les passages les plus pertinents,
        triés selon le score du CrossEncoder.
        """

        if not query or not query.strip():
            return []

        if not passages:
            return []

        safe_top_k = max(
            1,
            min(top_k, len(passages)),
        )

        pairs = [
            [
                query,
                passage.get("text", ""),
            ]
            for passage in passages
        ]

        try:
            scores = self.model.predict(
                pairs
            )

        except Exception:
            logger.exception(
                "Erreur pendant le re-ranking"
            )
            return passages[:safe_top_k]

        reranked_passages = []

        for passage, score in zip(
            passages,
            scores,
        ):
            enriched_passage = dict(passage)
            enriched_passage["rerank_score"] = float(score)

            reranked_passages.append(
                enriched_passage
            )

        reranked_passages.sort(
            key=lambda item: item["rerank_score"],
            reverse=True,
        )

        return reranked_passages[:safe_top_k]


RERANKER = ContractReranker()


def rerank_passages(
    query: str,
    passages: list[dict[str, Any]],
    top_k: int = 3,
) -> list[dict[str, Any]]:
    return RERANKER.rerank(
        query=query,
        passages=passages,
        top_k=top_k,
    )