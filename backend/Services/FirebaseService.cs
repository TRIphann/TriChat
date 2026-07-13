using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using backend.Models;
using System.IO;
using Microsoft.Extensions.Configuration;
using System;
using System.Text.Json;

namespace backend.Services;

public class FirebaseService
{
    public FirestoreDb FirestoreDb { get; }

    public FirebaseService(IConfiguration configuration)
    {
        var section = configuration.GetSection("Firebase");
        var credentialsFilePath = section.GetValue<string>("CredentialsFilePath");
        var projectId = section.GetValue<string>("ProjectId");
        var credentialsJson = section.GetValue<string>("CredentialsJson");

        if (string.IsNullOrWhiteSpace(projectId))
            throw new InvalidOperationException("Missing Firebase:ProjectId in appsettings.json or FIREBASE__PROJECTID env var.");

        GoogleCredential credential;

        if (!string.IsNullOrWhiteSpace(credentialsJson))
        {
            // Credentials được truyền trực tiếp qua JSON string (từ env var).
            // Render/Koyeb/Railway: đặt FIREBASE__CREDENTIALSJSON=<json_string>
            // trong dashboard environment variables.
            Console.WriteLine("[FIREBASE] Loading credentials from FIREBASE__CREDENTIALSJSON env var.");
            using var stream = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(credentialsJson));
            credential = GoogleCredential.FromStream(stream);
        }
        else if (!string.IsNullOrWhiteSpace(credentialsFilePath))
        {
            var resolvedPath = Path.GetFullPath(credentialsFilePath, AppContext.BaseDirectory);
            Console.WriteLine($"[FIREBASE] Resolved path: {resolvedPath}");
            Console.WriteLine($"[FIREBASE] File exists: {File.Exists(resolvedPath)}");
            if (!File.Exists(resolvedPath))
                throw new FileNotFoundException(
                    $"Firebase credentials file not found: {resolvedPath}. " +
                    "Set FIREBASE__CREDENTIALSJSON env var with the full JSON string instead.");
            credential = GoogleCredential.FromFile(resolvedPath);
        }
        else
        {
            throw new InvalidOperationException(
                "Missing Firebase credentials. Set FIREBASE__CREDENTIALSJSON env var with the service account JSON, " +
                "or Firebase:CredentialsFilePath in appsettings.json.");
        }

#pragma warning disable CS0618 // GoogleCredential.FromFile is deprecated; no replacement that works with FirestoreDbBuilder
        if (FirebaseApp.DefaultInstance == null)
        {
            FirebaseApp.Create(new AppOptions
            {
                Credential = credential,
                ProjectId = projectId
            });
        }
#pragma warning restore CS0618

        var builder = new FirestoreDbBuilder
        {
            ProjectId = projectId,
            Credential = credential
        };

        var databaseId = section.GetValue<string>("DatabaseId");
        if (!string.IsNullOrWhiteSpace(databaseId))
            builder.DatabaseId = databaseId;

        FirestoreDb = builder.Build();
        Console.WriteLine($"[FIREBASE] FirestoreDb initialized for project: {projectId}");
    }

    public async Task<UserRecord> CreateOrUpdateAuthUserAsync(string userId, string email)
    {
        if (string.IsNullOrWhiteSpace(userId))
            throw new ArgumentException("User ID is required.", nameof(userId));
        if (string.IsNullOrWhiteSpace(email))
            throw new ArgumentException("Email is required.", nameof(email));

        try
        {
            await FirebaseAuth.DefaultInstance.GetUserAsync(userId);
            var args = new UserRecordArgs
            {
                Uid = userId,
                Email = email.Trim(),
                EmailVerified = false
            };
            return await FirebaseAuth.DefaultInstance.UpdateUserAsync(args);
        }
        catch (FirebaseAuthException ex) when (ex.AuthErrorCode == AuthErrorCode.UserNotFound)
        {
            var args = new UserRecordArgs
            {
                Uid = userId,
                Email = email.Trim(),
                EmailVerified = false
            };
            return await FirebaseAuth.DefaultInstance.CreateUserAsync(args);
        }
    }

    public async Task<UserRecord?> UpdateAuthUserEmailAsync(string userId, string email)
    {
        if (string.IsNullOrWhiteSpace(userId))
            throw new ArgumentException("User ID is required.", nameof(userId));
        if (string.IsNullOrWhiteSpace(email))
            throw new ArgumentException("Email is required.", nameof(email));

        try
        {
            var args = new UserRecordArgs
            {
                Uid = userId,
                Email = email.Trim(),
                EmailVerified = false
            };
            return await FirebaseAuth.DefaultInstance.UpdateUserAsync(args);
        }
        catch (FirebaseAuthException ex) when (ex.AuthErrorCode == AuthErrorCode.UserNotFound)
        {
            return null;
        }
    }
}
