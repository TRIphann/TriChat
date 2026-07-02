using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Google.Cloud.Firestore;

namespace backend.Services
{
    public class StoryExpirationService(
    IServiceProvider serviceProvider,
    ILogger<StoryExpirationService> logger) : BackgroundService
{
    //  Run every hours
    private readonly TimeSpan _interval = TimeSpan.FromHours(1);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("[StoryExpiration] Background service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await MarkExpiredStoriesAsync();
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "[StoryExpiration] Error while marking expired stories");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task MarkExpiredStoriesAsync()
    {
        // BackgroundService is singleton so we need create a scope to use FirestoreDb
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<FirestoreDb>();

        var now = Timestamp.FromDateTime(DateTime.UtcNow);

        logger.LogInformation("[StoryExpiration] Scanning expired stories at {Time}", DateTime.Now);

        // Retrieve story-type feeds that haven't been marked as expired yet,
        // then filter the expiration check in memory. The composite
        // (type, settings.is_expired, settings.expires_at) index is not
        // guaranteed to exist on every deployment, so we rely on the
        // single-field index that Firestore creates by default for `type`.
        var snap = await db.Collection("feeds")
            .WhereEqualTo("type", "story")
            .GetSnapshotAsync();

        var expired = snap.Documents
            .Where(d => TryGetNestedBool(d, "settings.is_expired") == false
                && TryGetNestedTimestamp(d, "settings.expires_at") is { } ts
                && ts < now)
            .ToList();

        if (expired.Count == 0)
        {
            logger.LogInformation("[StoryExpiration] No expired stories found");
            return;
        }

        logger.LogInformation("[StoryExpiration] Found {Count} expired stories, updating...", expired.Count);

        // Use batch write to update multiple documents at once (up to 500 documents per batch).

        foreach (var chunk in expired.Chunk(500))
        {
            var batch = db.StartBatch();

            foreach (var doc in chunk)
            {
                batch.Update(doc.Reference, new Dictionary<string, object>
                {
                    ["settings.is_expired"] = true
                });
            }

            await batch.CommitAsync();
            logger.LogInformation("[StoryExpiration] Updated {Count} stories in batch", chunk.Length);
        }

        logger.LogInformation("[StoryExpiration] Done marking {Total} expired stories", expired.Count);
    }

    private static bool? TryGetNestedBool(DocumentSnapshot doc, string path)
    {
        var segments = path.Split('.');
        object current = doc.ToDictionary();
        foreach (var seg in segments)
        {
            if (current is IDictionary<string, object> dict && dict.TryGetValue(seg, out var next))
                current = next;
            else
                return null;
        }
        return current switch
        {
            bool b => b,
            null => null,
            _ => null
        };
    }

    private static Timestamp? TryGetNestedTimestamp(DocumentSnapshot doc, string path)
    {
        var segments = path.Split('.');
        object current = doc.ToDictionary();
        foreach (var seg in segments)
        {
            if (current is IDictionary<string, object> dict && dict.TryGetValue(seg, out var next))
                current = next;
            else
                return null;
        }
        return current is Timestamp t ? t : null;
    }
}
}