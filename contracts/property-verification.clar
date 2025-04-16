;; Property Verification Contract
;; Validates legitimate accommodation providers

(define-data-var admin principal tx-sender)

;; Property status: 0 = unverified, 1 = verified, 2 = suspended
(define-map properties
  { property-id: uint }
  {
    owner: principal,
    name: (string-utf8 100),
    location: (string-utf8 100),
    status: uint,
    registration-time: uint
  }
)

(define-data-var next-property-id uint u1)

;; Register a new property (unverified by default)
(define-public (register-property (name (string-utf8 100)) (location (string-utf8 100)))
  (let ((property-id (var-get next-property-id)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set properties
        { property-id: property-id }
        {
          owner: tx-sender,
          name: name,
          location: location,
          status: u0,
          registration-time: block-height
        }
      )
      (var-set next-property-id (+ property-id u1))
      (ok property-id)
    )
  )
)

;; Verify a property
(define-public (verify-property (property-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? properties { property-id: property-id })
      property (begin
        (map-set properties
          { property-id: property-id }
          (merge property { status: u1 })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Suspend a property
(define-public (suspend-property (property-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? properties { property-id: property-id })
      property (begin
        (map-set properties
          { property-id: property-id }
          (merge property { status: u2 })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Get property details
(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

;; Check if property is verified
(define-read-only (is-property-verified (property-id uint))
  (match (map-get? properties { property-id: property-id })
    property (is-eq (get status property) u1)
    false
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
