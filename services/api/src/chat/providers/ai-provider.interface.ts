export interface AiChatHistoryItem {
  role: 'user' | 'assistant';
  content: string;
}
export interface AiChatRequest {
  message: string;
  history?: AiChatHistoryItem[];
  systemPrompt: string;
  image?: string; // base64 data URL (image/png;base64,...)
}
export interface AiChatResponse {
  reply: string;
  provider: string;
}
export interface AiProvider {
  chat(request: AiChatRequest): Promise<AiChatResponse>;
}
