using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using backend.dtos.Response.Feeds;

namespace backend.dtos.Response
{
    public class FeedResponse
    {
        public string Id { get; init; } = string.Empty;
        public string Type { get; init; } = string.Empty;
        public string Privacy { get; init; } = string.Empty;
        public List<string> AllowedUserIds { get; init; } = new();

        // Flatten Stats fields for React frontend (post.likeCount, post.isLiked, etc.)
        // Note: Stats.IsLiked is set correctly by FeedService.ToResponse() before serialization.
        [JsonPropertyName("likeCount")]
        public int LikeCount => Stats?.LikeCount ?? 0;

        [JsonPropertyName("commentCount")]
        public int CommentCount => Stats?.CommentCount ?? 0;

        // The Stats object (with IsLiked) is already set correctly by FeedService.ToResponse()
        // Add a top-level isLiked alias so the frontend can read post.isLiked
        // instead of having to navigate post.stats.isLiked.
        [JsonPropertyName("isLiked")]
        public bool IsLiked => Stats?.IsLiked ?? false;

        [JsonPropertyName("viewCount")]
        public int ViewCount => Stats?.ViewCount ?? 0;

        public StatsResponse? Stats { get; set; }
        public SettingResponse? Settings { get; init; }

        // Flatten Author fields for React frontend (post.authorName, post.authorAvatar)
        [JsonPropertyName("authorName")]
        public string? AuthorName => Author?.Name;

        [JsonPropertyName("authorAvatar")]
        public string? AuthorAvatar => Author?.AvatarUrl;

        [JsonPropertyName("authorId")]
        public string? AuthorId => Author?.UserId;

        public AuthorResponse? Author { get; set; }

        [JsonIgnore] // Keep legacy field for the old flutter frontend
        public ContentResponse? Content { get; init; }

        public DateTime CreatedAt { get; init; }
        public DateTime? DeletedAt { get; init; }

        /// <summary>
        /// Flattened media URL — maps Content.Media[0].Url so the React frontend
        /// can read post.mediaUrl directly without navigating the nested structure.
        /// </summary>
        [JsonPropertyName("mediaUrl")]
        public string? MediaUrl => Content?.Media?.FirstOrDefault()?.Url;

        /// <summary>
        /// Flattened caption — maps Content.Caption as 'content' for React frontend.
        /// </summary>
        [JsonPropertyName("content")]
        public string? Content_ => Content?.Caption;

        [JsonPropertyName("caption")]
        public string? Caption => Content?.Caption;
    }
}
