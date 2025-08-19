(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_REGISTERED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_INPUTS (err u103))
(define-constant ERR_EXPIRED (err u104))
(define-constant ERR_NOT_VERIFIED (err u105))
(define-constant ERR_INSUFFICIENT_BALANCE (err u106))

(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var registration-fee uint u1000000)
(define-data-var verification-fee uint u500000)
(define-data-var total-identities uint u0)
(define-data-var total-aid-disbursed uint u0)

(define-map identities 
  principal 
  {
    full-name: (string-ascii 100),
    date-of-birth: (string-ascii 10),
    place-of-birth: (string-ascii 50),
    nationality: (string-ascii 30),
    biometric-hash: (string-ascii 64),
    registration-block: uint,
    verified: bool,
    verification-level: uint,
    last-updated: uint,
    emergency-contact: (optional principal),
    status: (string-ascii 20)
  }
)

(define-map verifiers
  principal
  {
    name: (string-ascii 50),
    organization: (string-ascii 100),
    authorized: bool,
    verification-count: uint,
    registration-block: uint
  }
)

(define-map credentials
  { identity: principal, credential-type: (string-ascii 30) }
  {
    issuer: principal,
    issue-date: uint,
    expiry-date: uint,
    data-hash: (string-ascii 64),
    verified: bool,
    revoked: bool
  }
)

(define-map aid-records
  { recipient: principal, aid-id: (string-ascii 50) }
  {
    provider: principal,
    amount: uint,
    aid-type: (string-ascii 30),
    disbursement-date: uint,
    location: (string-ascii 50),
    status: (string-ascii 20)
  }
)

(define-map access-permissions
  { identity: principal, service-provider: principal }
  {
    granted: bool,
    permissions: (list 10 (string-ascii 30)),
    granted-at: uint,
    expires-at: uint
  }
)

(define-map identity-sharing-logs
  { identity: principal, request-id: (string-ascii 50) }
  {
    requester: principal,
    data-shared: (list 5 (string-ascii 30)),
    timestamp: uint,
    purpose: (string-ascii 100),
    consent-given: bool
  }
)

(define-public (register-identity 
  (full-name (string-ascii 100))
  (date-of-birth (string-ascii 10))
  (place-of-birth (string-ascii 50))
  (nationality (string-ascii 30))
  (biometric-hash (string-ascii 64))
)
  (let
    (
      (current-balance (stx-get-balance tx-sender))
      (fee (var-get registration-fee))
    )
    (asserts! (>= current-balance fee) ERR_INSUFFICIENT_BALANCE)
    (asserts! (is-none (map-get? identities tx-sender)) ERR_ALREADY_REGISTERED)
    (asserts! (> (len full-name) u0) ERR_INVALID_INPUTS)
    (asserts! (> (len biometric-hash) u0) ERR_INVALID_INPUTS)
    
    (try! (stx-transfer? fee tx-sender (var-get contract-owner)))
    
    (map-set identities tx-sender
      {
        full-name: full-name,
        date-of-birth: date-of-birth,
        place-of-birth: place-of-birth,
        nationality: nationality,
        biometric-hash: biometric-hash,
        registration-block: stacks-block-height,
        verified: false,
        verification-level: u0,
        last-updated: stacks-block-height,
        emergency-contact: none,
        status: "active"
      }
    )
    
    (var-set total-identities (+ (var-get total-identities) u1))
    (ok tx-sender)
  )
)

(define-public (register-verifier 
  (verifier principal)
  (name (string-ascii 50))
  (organization (string-ascii 100))
)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? verifiers verifier)) ERR_ALREADY_REGISTERED)
    
    (map-set verifiers verifier
      {
        name: name,
        organization: organization,
        authorized: true,
        verification-count: u0,
        registration-block: stacks-block-height
      }
    )
    (ok verifier)
  )
)

(define-public (verify-identity 
  (identity principal) 
  (verification-level uint)
)
  (let
    (
      (verifier-info (unwrap! (map-get? verifiers tx-sender) ERR_NOT_AUTHORIZED))
      (identity-info (unwrap! (map-get? identities identity) ERR_NOT_FOUND))
      (current-balance (stx-get-balance identity))
      (fee (var-get verification-fee))
    )
    (asserts! (get authorized verifier-info) ERR_NOT_AUTHORIZED)
    (asserts! (>= current-balance fee) ERR_INSUFFICIENT_BALANCE)
    (asserts! (<= verification-level u5) ERR_INVALID_INPUTS)
    
    (try! (stx-transfer? fee identity (var-get contract-owner)))
    
    (map-set identities identity
      (merge identity-info {
        verified: true,
        verification-level: verification-level,
        last-updated: stacks-block-height
      })
    )
    
    (map-set verifiers tx-sender
      (merge verifier-info {
        verification-count: (+ (get verification-count verifier-info) u1)
      })
    )
    
    (ok identity)
  )
)

(define-public (issue-credential
  (identity principal)
  (credential-type (string-ascii 30))
  (expiry-date uint)
  (data-hash (string-ascii 64))
)
  (let
    (
      (verifier-info (unwrap! (map-get? verifiers tx-sender) ERR_NOT_AUTHORIZED))
      (identity-info (unwrap! (map-get? identities identity) ERR_NOT_FOUND))
    )
    (asserts! (get authorized verifier-info) ERR_NOT_AUTHORIZED)
    (asserts! (get verified identity-info) ERR_NOT_VERIFIED)
    (asserts! (> expiry-date stacks-block-height) ERR_INVALID_INPUTS)
    
    (map-set credentials { identity: identity, credential-type: credential-type }
      {
        issuer: tx-sender,
        issue-date: stacks-block-height,
        expiry-date: expiry-date,
        data-hash: data-hash,
        verified: true,
        revoked: false
      }
    )
    (ok true)
  )
)

(define-public (record-aid-disbursement
  (recipient principal)
  (aid-id (string-ascii 50))
  (amount uint)
  (aid-type (string-ascii 30))
  (location (string-ascii 50))
)
  (let
    (
      (identity-info (unwrap! (map-get? identities recipient) ERR_NOT_FOUND))
    )
    (asserts! (get verified identity-info) ERR_NOT_VERIFIED)
    (asserts! (> amount u0) ERR_INVALID_INPUTS)
    
    (map-set aid-records { recipient: recipient, aid-id: aid-id }
      {
        provider: tx-sender,
        amount: amount,
        aid-type: aid-type,
        disbursement-date: stacks-block-height,
        location: location,
        status: "disbursed"
      }
    )
    
    (var-set total-aid-disbursed (+ (var-get total-aid-disbursed) amount))
    (ok aid-id)
  )
)

(define-public (grant-access-permission
  (service-provider principal)
  (permissions (list 10 (string-ascii 30)))
  (expires-at uint)
)
  (let
    (
      (identity-info (unwrap! (map-get? identities tx-sender) ERR_NOT_FOUND))
    )
    (asserts! (get verified identity-info) ERR_NOT_VERIFIED)
    (asserts! (> expires-at stacks-block-height) ERR_INVALID_INPUTS)
    
    (map-set access-permissions { identity: tx-sender, service-provider: service-provider }
      {
        granted: true,
        permissions: permissions,
        granted-at: stacks-block-height,
        expires-at: expires-at
      }
    )
    (ok true)
  )
)

(define-public (revoke-access-permission (service-provider principal))
  (let
    (
      (access-info (unwrap! (map-get? access-permissions { identity: tx-sender, service-provider: service-provider }) ERR_NOT_FOUND))
    )
    (map-set access-permissions { identity: tx-sender, service-provider: service-provider }
      (merge access-info { granted: false })
    )
    (ok true)
  )
)

(define-public (log-data-sharing
  (identity principal)
  (request-id (string-ascii 50))
  (data-shared (list 5 (string-ascii 30)))
  (purpose (string-ascii 100))
  (consent-given bool)
)
  (begin
    (asserts! (or (is-eq tx-sender identity) (is-some (map-get? verifiers tx-sender))) ERR_NOT_AUTHORIZED)
    
    (map-set identity-sharing-logs { identity: identity, request-id: request-id }
      {
        requester: tx-sender,
        data-shared: data-shared,
        timestamp: stacks-block-height,
        purpose: purpose,
        consent-given: consent-given
      }
    )
    (ok request-id)
  )
)

(define-public (update-identity-status 
  (identity principal) 
  (new-status (string-ascii 20))
)
  (let
    (
      (identity-info (unwrap! (map-get? identities identity) ERR_NOT_FOUND))
    )
    (asserts! (or (is-eq tx-sender identity) (is-eq tx-sender (var-get contract-owner))) ERR_NOT_AUTHORIZED)
    
    (map-set identities identity
      (merge identity-info {
        status: new-status,
        last-updated: stacks-block-height
      })
    )
    (ok identity)
  )
)

(define-public (set-emergency-contact (emergency-contact principal))
  (let
    (
      (identity-info (unwrap! (map-get? identities tx-sender) ERR_NOT_FOUND))
    )
    (map-set identities tx-sender
      (merge identity-info {
        emergency-contact: (some emergency-contact),
        last-updated: stacks-block-height
      })
    )
    (ok emergency-contact)
  )
)

(define-read-only (get-identity (identity principal))
  (map-get? identities identity)
)

(define-read-only (get-verifier (verifier principal))
  (map-get? verifiers verifier)
)

(define-read-only (get-credential (identity principal) (credential-type (string-ascii 30)))
  (map-get? credentials { identity: identity, credential-type: credential-type })
)

(define-read-only (get-aid-record (recipient principal) (aid-id (string-ascii 50)))
  (map-get? aid-records { recipient: recipient, aid-id: aid-id })
)

(define-read-only (get-access-permission (identity principal) (service-provider principal))
  (map-get? access-permissions { identity: identity, service-provider: service-provider })
)

(define-read-only (get-sharing-log (identity principal) (request-id (string-ascii 50)))
  (map-get? identity-sharing-logs { identity: identity, request-id: request-id })
)

(define-read-only (is-identity-verified (identity principal))
  (match (map-get? identities identity)
    identity-data (get verified identity-data)
    false
  )
)

(define-read-only (has-valid-credential (identity principal) (credential-type (string-ascii 30)))
  (match (map-get? credentials { identity: identity, credential-type: credential-type })
    cred-data (and 
      (get verified cred-data)
      (not (get revoked cred-data))
      (> (get expiry-date cred-data) stacks-block-height)
    )
    false
  )
)

(define-read-only (get-contract-stats)
  {
    total-identities: (var-get total-identities),
    total-aid-disbursed: (var-get total-aid-disbursed),
    registration-fee: (var-get registration-fee),
    verification-fee: (var-get verification-fee)
  }
)

(define-public (update-fees (new-registration-fee uint) (new-verification-fee uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (var-set registration-fee new-registration-fee)
    (var-set verification-fee new-verification-fee)
    (ok true)
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (var-set contract-owner new-owner)
    (ok new-owner)
  )
)
