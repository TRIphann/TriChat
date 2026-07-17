"""TriChat OTP smoke test
Goi truc tiep endpoint /api/otp/generate tren Render de trigger Resend gui mail.
"""
import json
import sys
import urllib.request
import urllib.error

RENDER_BASE = "https://trichat.onrender.com"
TARGET_EMAIL = "pcongtri31@gmail.com"


def post_json(url: str, payload: dict, timeout: int = 30) -> tuple[int, str]:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="replace")


def main() -> int:
    url = f"{RENDER_BASE}/api/otp/generate"
    print(f"[POST] {url}")
    print(f"Body : {{\"email\": \"{TARGET_EMAIL}\"}}")

    status, body = post_json(url, {"email": TARGET_EMAIL})
    print(f"Status: {status}")
    print("Body  :")
    print(body)

    print()
    print("-" * 60)
    print("Neu status=200 va body.otp != null -> email send that bai,")
    print("   Resend fallback tra OTP trong response de hien thi trong app.")
    print("Kiem hop thu:", TARGET_EMAIL)
    return 0 if 200 <= status < 300 else 1


if __name__ == "__main__":
    sys.exit(main())
