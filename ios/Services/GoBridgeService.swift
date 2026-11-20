import Foundation

// MARK: - Go Bridge Response Envelope
public struct BridgeResponse<T: Decodable>: Decodable {
    public let success: Bool
    public let data: T?
    public let error: String?
}

// MARK: - Custom Bridge Error
public enum GoBridgeError: LocalizedError {
    case initializationFailed(String)
    case bridgeError(String)
    case serializationError(String)
    case decodingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let msg): return "Inisialisasi database gagal: \(msg)"
        case .bridgeError(let msg): return msg
        case .serializationError(let msg): return "Gagal serialize payload: \(msg)"
        case .decodingError(let msg): return "Gagal membaca data dari Core: \(msg)"
        }
    }
}

// MARK: - GoBridge Service (Actor for thread safety)
public actor GoBridgeService {
    public static let shared = GoBridgeService()
    
    private var isInitialized = false
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    
    private init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder
    }
    
    /// Initializes database in app's Application Support / Documents directory
    public func initialize() throws {
        guard !isInitialized else { return }
        
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbUrl = appSupport.appendingPathComponent("lumina_v1.db")
        let dbPath = dbUrl.path
        
        #if canImport(LuminaCore)
        let initJsonResult = LuminaCoreLuminaInit(dbPath)
        guard let data = initJsonResult.data(using: .utf8) else {
            throw GoBridgeError.initializationFailed("Invalid response string from LuminaInit")
        }
        let env = try jsonDecoder.decode(BridgeResponse<[String: String]>.self, from: data)
        if !env.success {
            throw GoBridgeError.initializationFailed(env.error ?? "Unknown error")
        }
        #else
        print("[GoBridge] LuminaCore framework running in Mock/Preview mode at: \(dbPath)")
        #endif
        
        isInitialized = true
    }
    
    /// Dispatches an action to Go core on background thread and decodes JSON response
    public func dispatch<T: Decodable>(action: String, payload: Any? = nil) async throws -> T {
        if !isInitialized {
            try initialize()
        }
        
        var payloadJson = ""
        if let payload = payload {
            if let str = payload as? String {
                payloadJson = str
            } else if let encodable = payload as? Encodable {
                let data = try jsonEncoder.encode(AnyEncodable(encodable))
                payloadJson = String(data: data, encoding: .utf8) ?? ""
            } else {
                let data = try JSONSerialization.data(withJSONObject: payload, options: [])
                payloadJson = String(data: data, encoding: .utf8) ?? ""
            }
        }
        
        return try await Task.detached(priority: .userInitiated) { [jsonDecoder] () -> T in
            #if canImport(LuminaCore)
            let resultJson = LuminaCoreLuminaDispatch(action, payloadJson)
            guard let data = resultJson.data(using: .utf8) else {
                throw GoBridgeError.decodingError("Empty response from Core")
            }
            
            let envelope = try jsonDecoder.decode(BridgeResponse<T>.self, from: data)
            if !envelope.success {
                throw GoBridgeError.bridgeError(envelope.error ?? "Unknown Core error")
            }
            guard let responseData = envelope.data else {
                throw GoBridgeError.decodingError("Missing data payload from Core response")
            }
            return responseData
            #else
            // Mock preview fallback for SwiftUI canvas
            return try MockBridgeHandler.mockDispatch(action: action)
            #endif
        }.value
    }
}

// MARK: - Encodable Type Eraser Helper
public struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    
    public init(_ encodable: Encodable) {
        self.encodeFunc = encodable.encode
    }
    
    public func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
