import { apiRequest } from "./http";
import type {
  ConversationDetailDto,
  ConversationSummaryDto,
  MessageDto,
  MessageStatus,
  PageResponse,
} from "../types/api";

export interface ConversationsSearchParams {
  status?: MessageStatus;
  unreadOnly?: boolean;
  userId?: string;
  search?: string;
  page?: number;
  size?: number;
  sort?: string;
}

export const conversationsApi = {
  search(params: ConversationsSearchParams = {}) {
    return apiRequest<PageResponse<ConversationSummaryDto>>(
      "/api/admin/conversations",
      { query: { ...params } },
    );
  },

  getDetail(id: string) {
    return apiRequest<ConversationDetailDto>(`/api/admin/conversations/${id}`);
  },

  markRead(id: string) {
    return apiRequest<ConversationDetailDto>(
      `/api/admin/conversations/${id}/mark-read`,
      { method: "POST" },
    );
  },

  reply(id: string, body: string) {
    return apiRequest<MessageDto>(`/api/admin/conversations/${id}/reply`, {
      method: "POST",
      body: { body },
    });
  },

  updateStatus(id: string, status: MessageStatus) {
    return apiRequest<ConversationDetailDto>(
      `/api/admin/conversations/${id}/status`,
      { method: "PATCH", body: { status } },
    );
  },

  delete(id: string) {
    return apiRequest<void>(`/api/admin/conversations/${id}`, {
      method: "DELETE",
    });
  },

  unreadCount() {
    return apiRequest<{ count: number }>(
      "/api/admin/conversations/unread-count",
    );
  },
};
