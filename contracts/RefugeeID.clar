(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_REGISTERED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_INPUTS (err u103))
(define-constant ERR_EXPIRED (err u104))
(define-constant ERR_NOT_VERIFIED (err u105))
(define-constant ERR_INSUFFICIENT_BALANCE (err u106))
(define-constant ERR_SELF_RELATIONSHIP (err u107))
(define-constant ERR_RELATIONSHIP_EXISTS (err u108))
(define-constant ERR_INVALID_RELATIONSHIP (err u109))
(define-constant ERR_INVALID_RATING (err u110))
(define-constant ERR_PROVIDER_NOT_FOUND (err u111))
(define-constant ERR_DUPLICATE_RATING (err u112))
(define-constant ERR_SUPPLY_EXISTS (err u113))
(define-constant ERR_SUPPLY_NOT_FOUND (err u114))
(define-constant ERR_INVALID_QUANTITY (err u115))
(define-constant ERR_OUT_OF_STOCK (err u116))
(define-constant ERR_DUPLICATE_DISTRIBUTION (err u117))

(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var registration-fee uint u1000000)
(define-data-var verification-fee uint u500000)
(define-data-var total-identities uint u0)
(define-data-var total-aid-disbursed uint u0)
(define-data-var total-family-links uint u0)
(define-data-var total-provider-ratings uint u0)
(define-data-var total-supplies uint u0)
(define-data-var total-supplies-distributed uint u0)

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

(define-map family-relationships
  { person1: principal, person2: principal }
  {
    relationship-type: (string-ascii 20),
    established-date: uint,
    verified: bool,
    verified-by: (optional principal),
    verification-date: (optional uint),
    mutual-consent: bool,
    status: (string-ascii 15)
  }
)

(define-map family-search-registry
  principal
  {
    seeking-family: bool,
    contact-info: (string-ascii 100),
    last-known-location: (string-ascii 50),
    search-details: (string-ascii 200),
    registration-date: uint
  }
)

(define-map emergency-family-alerts
  { family-member: principal, alert-id: (string-ascii 30) }
  {
    sender: principal,
    alert-type: (string-ascii 25),
    message: (string-ascii 150),
    location: (string-ascii 50),
    timestamp: uint,
    priority-level: uint,
    acknowledged: bool
  }
)

(define-map provider-ratings
  { provider: principal, rater: principal }
  {
    rating: uint,
    feedback: (string-ascii 100),
    timestamp: uint,
    verified-by: principal
  }
)

(define-map provider-stats
  principal
  {
    total-ratings: uint,
    average-rating: uint,
    total-feedback-count: uint
  }
)

(define-map medical-supplies
  (string-ascii 30)
  {
    name: (string-ascii 50),
    description: (string-ascii 100),
    unit: (string-ascii 20),
    total-quantity: uint,
    available-quantity: uint,
    creator: principal,
    created-at: uint,
    last-updated: uint,
    active: bool
  }
)

(define-map supply-distributions
  { supply-id: (string-ascii 30), distribution-id: (string-ascii 50) }
  {
    recipient: principal,
    provider: principal,
    quantity: uint,
    location: (string-ascii 50),
    timestamp: uint
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

(define-public (establish-family-relationship
  (family-member principal)
  (relationship-type (string-ascii 20))
)
  (let
    (
      (sender-identity (unwrap! (map-get? identities tx-sender) ERR_NOT_FOUND))
      (family-identity (unwrap! (map-get? identities family-member) ERR_NOT_FOUND))
      (relationship-key1 { person1: tx-sender, person2: family-member })
      (relationship-key2 { person1: family-member, person2: tx-sender })
    )
    (asserts! (not (is-eq tx-sender family-member)) ERR_SELF_RELATIONSHIP)
    (asserts! (get verified sender-identity) ERR_NOT_VERIFIED)
    (asserts! (get verified family-identity) ERR_NOT_VERIFIED)
    (asserts! (is-none (map-get? family-relationships relationship-key1)) ERR_RELATIONSHIP_EXISTS)
    (asserts! (is-none (map-get? family-relationships relationship-key2)) ERR_RELATIONSHIP_EXISTS)
    (asserts! (> (len relationship-type) u0) ERR_INVALID_INPUTS)

    (map-set family-relationships relationship-key1
      {
        relationship-type: relationship-type,
        established-date: stacks-block-height,
        verified: false,
        verified-by: none,
        verification-date: none,
        mutual-consent: false,
        status: "pending"
      }
    )
    
    (var-set total-family-links (+ (var-get total-family-links) u1))
    (ok relationship-key1)
  )
)

(define-public (confirm-family-relationship
  (family-member principal)
)
  (let
    (
      (relationship-key1 { person1: family-member, person2: tx-sender })
      (relationship-key2 { person1: tx-sender, person2: family-member })
      (relationship-info (unwrap! (map-get? family-relationships relationship-key1) ERR_NOT_FOUND))
    )
    (asserts! (is-eq (get status relationship-info) "pending") ERR_INVALID_RELATIONSHIP)
    
    (map-set family-relationships relationship-key1
      (merge relationship-info {
        mutual-consent: true,
        status: "confirmed"
      })
    )
    
    (map-set family-relationships relationship-key2
      {
        relationship-type: (get relationship-type relationship-info),
        established-date: (get established-date relationship-info),
        verified: false,
        verified-by: none,
        verification-date: none,
        mutual-consent: true,
        status: "confirmed"
      }
    )
    (ok true)
  )
)

(define-public (verify-family-relationship
  (person1 principal)
  (person2 principal)
)
  (let
    (
      (verifier-info (unwrap! (map-get? verifiers tx-sender) ERR_NOT_AUTHORIZED))
      (relationship-key { person1: person1, person2: person2 })
      (relationship-info (unwrap! (map-get? family-relationships relationship-key) ERR_NOT_FOUND))
    )
    (asserts! (get authorized verifier-info) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status relationship-info) "confirmed") ERR_INVALID_RELATIONSHIP)
    
    (map-set family-relationships relationship-key
      (merge relationship-info {
        verified: true,
        verified-by: (some tx-sender),
        verification-date: (some stacks-block-height),
        status: "verified"
      })
    )
    (ok true)
  )
)

(define-public (register-for-family-search
  (contact-info (string-ascii 100))
  (last-known-location (string-ascii 50))
  (search-details (string-ascii 200))
)
  (let
    (
      (identity-info (unwrap! (map-get? identities tx-sender) ERR_NOT_FOUND))
    )
    (asserts! (get verified identity-info) ERR_NOT_VERIFIED)
    (asserts! (> (len contact-info) u0) ERR_INVALID_INPUTS)
    
    (map-set family-search-registry tx-sender
      {
        seeking-family: true,
        contact-info: contact-info,
        last-known-location: last-known-location,
        search-details: search-details,
        registration-date: stacks-block-height
      }
    )
    (ok true)
  )
)

(define-public (send-emergency-family-alert
  (family-member principal)
  (alert-id (string-ascii 30))
  (alert-type (string-ascii 25))
  (message (string-ascii 150))
  (location (string-ascii 50))
  (priority-level uint)
)
  (let
    (
      (sender-identity (unwrap! (map-get? identities tx-sender) ERR_NOT_FOUND))
      (relationship-key { person1: tx-sender, person2: family-member })
      (relationship-info (map-get? family-relationships relationship-key))
    )
    (asserts! (get verified sender-identity) ERR_NOT_VERIFIED)
    (asserts! (is-some relationship-info) ERR_NOT_FOUND)
    (asserts! (> (len alert-id) u0) ERR_INVALID_INPUTS)
    (asserts! (<= priority-level u5) ERR_INVALID_INPUTS)
    
    (map-set emergency-family-alerts { family-member: family-member, alert-id: alert-id }
      {
        sender: tx-sender,
        alert-type: alert-type,
        message: message,
        location: location,
        timestamp: stacks-block-height,
        priority-level: priority-level,
        acknowledged: false
      }
    )
    (ok alert-id)
  )
)

(define-public (acknowledge-family-alert
  (sender principal)
  (alert-id (string-ascii 30))
)
  (let
    (
      (alert-key { family-member: tx-sender, alert-id: alert-id })
      (alert-info (unwrap! (map-get? emergency-family-alerts alert-key) ERR_NOT_FOUND))
    )
    (asserts! (is-eq (get sender alert-info) sender) ERR_NOT_AUTHORIZED)
    
    (map-set emergency-family-alerts alert-key
      (merge alert-info { acknowledged: true })
    )
    (ok true)
  )
)

(define-public (dissolve-family-relationship
  (family-member principal)
)
  (let
    (
      (relationship-key1 { person1: tx-sender, person2: family-member })
      (relationship-key2 { person1: family-member, person2: tx-sender })
      (relationship-info (unwrap! (map-get? family-relationships relationship-key1) ERR_NOT_FOUND))
    )
    (map-set family-relationships relationship-key1
      (merge relationship-info { status: "dissolved" })
    )
    
    (match (map-get? family-relationships relationship-key2)
      reverse-rel (map-set family-relationships relationship-key2
        (merge reverse-rel { status: "dissolved" }))
      true
    )
    (ok true)
  )
)

(define-public (rate-service-provider
  (provider principal)
  (rating uint)
  (feedback (string-ascii 100))
)
  (let
    (
      (rater-identity (unwrap! (map-get? identities tx-sender) ERR_NOT_FOUND))
      (existing-stats (map-get? provider-stats provider))
      (existing-rating (map-get? provider-ratings { provider: provider, rater: tx-sender }))
    )
    (asserts! (not (is-eq tx-sender provider)) ERR_SELF_RELATIONSHIP)
    (asserts! (get verified rater-identity) ERR_NOT_VERIFIED)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_RATING)
    (asserts! (> (len feedback) u0) ERR_INVALID_INPUTS)
    (asserts! (is-none existing-rating) ERR_DUPLICATE_RATING)
    
    (map-set provider-ratings { provider: provider, rater: tx-sender }
      {
        rating: rating,
        feedback: feedback,
        timestamp: stacks-block-height,
        verified-by: tx-sender
      }
    )
    
    (match existing-stats
      stats (let
        (
          (new-total (+ (get total-ratings stats) u1))
          (sum-ratings (+ (* (get average-rating stats) (get total-ratings stats)) rating))
          (new-average (/ sum-ratings new-total))
        )
        (map-set provider-stats provider {
          total-ratings: new-total,
          average-rating: new-average,
          total-feedback-count: (+ (get total-feedback-count stats) u1)
        })
      )
      (map-set provider-stats provider {
        total-ratings: u1,
        average-rating: rating,
        total-feedback-count: u1
      })
    )
    
    (var-set total-provider-ratings (+ (var-get total-provider-ratings) u1))
    (ok true)
  )
)

(define-public (update-provider-rating
  (provider principal)
  (new-rating uint)
  (new-feedback (string-ascii 100))
)
  (let
    (
      (rater-identity (unwrap! (map-get? identities tx-sender) ERR_NOT_FOUND))
      (existing-rating (unwrap! (map-get? provider-ratings { provider: provider, rater: tx-sender }) ERR_NOT_FOUND))
      (provider-stats-info (unwrap! (map-get? provider-stats provider) ERR_PROVIDER_NOT_FOUND))
    )
    (asserts! (get verified rater-identity) ERR_NOT_VERIFIED)
    (asserts! (and (>= new-rating u1) (<= new-rating u5)) ERR_INVALID_RATING)
    (asserts! (> (len new-feedback) u0) ERR_INVALID_INPUTS)
    
    (let
      (
        (old-rating (get rating existing-rating))
        (old-sum (* (get average-rating provider-stats-info) (get total-ratings provider-stats-info)))
        (new-sum (- (+ old-sum new-rating) old-rating))
        (new-average (/ new-sum (get total-ratings provider-stats-info)))
      )
      (map-set provider-ratings { provider: provider, rater: tx-sender }
        (merge existing-rating {
          rating: new-rating,
          feedback: new-feedback,
          timestamp: stacks-block-height
        })
      )
      
      (map-set provider-stats provider (merge provider-stats-info {
        average-rating: new-average
      }))
    )
    
    (ok true)
  )
)

(define-public (register-medical-supply
  (supply-id (string-ascii 30))
  (name (string-ascii 50))
  (description (string-ascii 100))
  (unit (string-ascii 20))
  (initial-quantity uint)
)
  (let
    (
      (verifier-info (unwrap! (map-get? verifiers tx-sender) ERR_NOT_AUTHORIZED))
    )
    (asserts! (get authorized verifier-info) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? medical-supplies supply-id)) ERR_SUPPLY_EXISTS)
    (asserts! (> (len supply-id) u0) ERR_INVALID_INPUTS)
    (asserts! (> (len name) u0) ERR_INVALID_INPUTS)
    (asserts! (> initial-quantity u0) ERR_INVALID_QUANTITY)

    (map-set medical-supplies supply-id {
      name: name,
      description: description,
      unit: unit,
      total-quantity: initial-quantity,
      available-quantity: initial-quantity,
      creator: tx-sender,
      created-at: stacks-block-height,
      last-updated: stacks-block-height,
      active: true
    })

    (var-set total-supplies (+ (var-get total-supplies) u1))
    (ok supply-id)
  )
)

(define-public (restock-medical-supply
  (supply-id (string-ascii 30))
  (added-quantity uint)
)
  (let
    (
      (verifier-info (unwrap! (map-get? verifiers tx-sender) ERR_NOT_AUTHORIZED))
      (supply-info (unwrap! (map-get? medical-supplies supply-id) ERR_SUPPLY_NOT_FOUND))
    )
    (asserts! (get authorized verifier-info) ERR_NOT_AUTHORIZED)
    (asserts! (> added-quantity u0) ERR_INVALID_QUANTITY)

    (map-set medical-supplies supply-id
      (merge supply-info {
        total-quantity: (+ (get total-quantity supply-info) added-quantity),
        available-quantity: (+ (get available-quantity supply-info) added-quantity),
        last-updated: stacks-block-height
      })
    )
    (ok true)
  )
)

(define-public (distribute-medical-supply
  (recipient principal)
  (supply-id (string-ascii 30))
  (distribution-id (string-ascii 50))
  (quantity uint)
  (location (string-ascii 50))
)
  (let
    (
      (verifier-info (unwrap! (map-get? verifiers tx-sender) ERR_NOT_AUTHORIZED))
      (identity-info (unwrap! (map-get? identities recipient) ERR_NOT_FOUND))
      (supply-info (unwrap! (map-get? medical-supplies supply-id) ERR_SUPPLY_NOT_FOUND))
    )
    (asserts! (get authorized verifier-info) ERR_NOT_AUTHORIZED)
    (asserts! (get verified identity-info) ERR_NOT_VERIFIED)
    (asserts! (> quantity u0) ERR_INVALID_QUANTITY)
    (asserts! (>= (get available-quantity supply-info) quantity) ERR_OUT_OF_STOCK)
    (asserts! (is-none (map-get? supply-distributions { supply-id: supply-id, distribution-id: distribution-id })) ERR_DUPLICATE_DISTRIBUTION)

    (map-set supply-distributions { supply-id: supply-id, distribution-id: distribution-id } {
      recipient: recipient,
      provider: tx-sender,
      quantity: quantity,
      location: location,
      timestamp: stacks-block-height
    })

    (map-set medical-supplies supply-id
      (merge supply-info {
        available-quantity: (- (get available-quantity supply-info) quantity),
        last-updated: stacks-block-height
      })
    )

    (var-set total-supplies-distributed (+ (var-get total-supplies-distributed) quantity))
    (ok distribution-id)
  )
)

(define-read-only (get-medical-supply (supply-id (string-ascii 30)))
  (map-get? medical-supplies supply-id)
)

(define-read-only (get-supply-distribution (supply-id (string-ascii 30)) (distribution-id (string-ascii 50)))
  (map-get? supply-distributions { supply-id: supply-id, distribution-id: distribution-id })
)

(define-read-only (get-supply-stats)
  {
    total-supplies: (var-get total-supplies),
    total-supplies-distributed: (var-get total-supplies-distributed)
  }
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
    total-family-links: (var-get total-family-links),
    registration-fee: (var-get registration-fee),
    verification-fee: (var-get verification-fee)
  }
)

(define-read-only (get-family-relationship (person1 principal) (person2 principal))
  (map-get? family-relationships { person1: person1, person2: person2 })
)

(define-read-only (get-family-search-info (identity principal))
  (map-get? family-search-registry identity)
)

(define-read-only (get-emergency-alert (family-member principal) (alert-id (string-ascii 30)))
  (map-get? emergency-family-alerts { family-member: family-member, alert-id: alert-id })
)

(define-read-only (is-family-relationship-verified (person1 principal) (person2 principal))
  (match (map-get? family-relationships { person1: person1, person2: person2 })
    relationship-data (and 
      (get verified relationship-data)
      (is-eq (get status relationship-data) "verified")
    )
    false
  )
)

(define-read-only (has-mutual-family-consent (person1 principal) (person2 principal))
  (match (map-get? family-relationships { person1: person1, person2: person2 })
    relationship-data (get mutual-consent relationship-data)
    false
  )
)

(define-read-only (get-provider-rating (provider principal) (rater principal))
  (map-get? provider-ratings { provider: provider, rater: rater })
)

(define-read-only (get-provider-stats (provider principal))
  (map-get? provider-stats provider)
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
