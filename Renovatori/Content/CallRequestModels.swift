import Foundation

/// `GET /call-requests/captcha`: the web form's math captcha.
struct CallRequestCaptcha: Decodable {
    /// SVG markup of the expression to solve.
    let svg: String
    /// Signed answer, sent back with the visitor's answer.
    let hash: String
}

struct CallRequestCaptchaResponse: Decodable {
    let captcha: CallRequestCaptcha
}

/// Body of `POST /call-requests`.
struct CallRequestBody: Encodable {
    let phone: String
    let email: String
    let description: String
    let captchaInput: String
    let captchaHash: String
}

struct CallRequestResponse: Decodable {
    struct Created: Decodable {
        let id: String
    }

    let callRequest: Created
}
