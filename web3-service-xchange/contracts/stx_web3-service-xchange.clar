;; P2P Service Marketplace Smart Contract
;; A decentralized marketplace for peer-to-peer services

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-service-unavailable (err u104))
(define-constant err-booking-not-found (err u105))
(define-constant err-invalid-status (err u106))
(define-constant err-already-reviewed (err u107))
(define-constant err-insufficient-funds (err u108))

;; Data Variables
(define-data-var next-service-id uint u1)
(define-data-var next-booking-id uint u1)
(define-data-var platform-fee-percentage uint u250) ;; 2.5% = 250 basis points

;; Service status constants
(define-constant service-active u1)
(define-constant service-paused u2)
(define-constant service-inactive u3)

;; Booking status constants
(define-constant booking-pending u1)
(define-constant booking-confirmed u2)
(define-constant booking-completed u3)
(define-constant booking-cancelled u4)
(define-constant booking-disputed u5)

;; Data Maps
(define-map services
  uint
  {
    provider: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    price-per-hour: uint,
    currency: (string-ascii 10),
    availability: (string-ascii 200),
    status: uint,
    rating: uint,
    total-reviews: uint,
    created-at: uint
  }
)

(define-map bookings
  uint
  {
    service-id: uint,
    client: principal,
    provider: principal,
    hours: uint,
    total-amount: uint,
    platform-fee: uint,
    status: uint,
    scheduled-time: uint,
    created-at: uint,
    completed-at: (optional uint)
  }
)

(define-map reviews
  {booking-id: uint, reviewer: principal}
  {
    rating: uint,
    comment: (string-ascii 500),
    created-at: uint
  }
)

(define-map user-profiles
  principal
  {
    name: (string-ascii 50),
    bio: (string-ascii 300),
    skills: (string-ascii 200),
    total-services: uint,
    total-bookings: uint,
    average-rating: uint,
    is-verified: bool,
    joined-at: uint
  }
)

(define-map service-categories
  (string-ascii 50)
  bool
)

;; Escrow for holding payments
(define-map escrow
  uint ;; booking-id
  uint ;; amount
)

;; Initialize categories
(map-set service-categories "web-development" true)
(map-set service-categories "graphic-design" true)
(map-set service-categories "writing" true)
(map-set service-categories "consulting" true)
(map-set service-categories "tutoring" true)
(map-set service-categories "photography" true)
(map-set service-categories "marketing" true)
(map-set service-categories "music" true)

;; Read-only functions
(define-read-only (get-service (service-id uint))
  (map-get? services service-id)
)

(define-read-only (get-booking (booking-id uint))
  (map-get? bookings booking-id)
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles user)
)

(define-read-only (get-review (booking-id uint) (reviewer principal))
  (map-get? reviews {booking-id: booking-id, reviewer: reviewer})
)

(define-read-only (get-platform-fee-percentage)
  (var-get platform-fee-percentage)
)

(define-read-only (get-next-service-id)
  (var-get next-service-id)
)

(define-read-only (get-next-booking-id)
  (var-get next-booking-id)
)

(define-read-only (is-category-valid (category (string-ascii 50)))
  (default-to false (map-get? service-categories category))
)

(define-read-only (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-percentage)) u10000)
)

;; Public functions

;; Create user profile
(define-public (create-profile (name (string-ascii 50)) (bio (string-ascii 300)) (skills (string-ascii 200)))
  (let ((user tx-sender))
    (map-set user-profiles user {
      name: name,
      bio: bio,
      skills: skills,
      total-services: u0,
      total-bookings: u0,
      average-rating: u0,
      is-verified: false,
      joined-at: stacks-block-height
    })
    (ok true)
  )
)

;; Update user profile
(define-public (update-profile (name (string-ascii 50)) (bio (string-ascii 300)) (skills (string-ascii 200)))
  (let ((existing-profile (unwrap! (map-get? user-profiles tx-sender) err-not-found)))
    (map-set user-profiles tx-sender (merge existing-profile {
      name: name,
      bio: bio,
      skills: skills
    }))
    (ok true)
  )
)

;; Create a new service
(define-public (create-service 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (price-per-hour uint)
  (currency (string-ascii 10))
  (availability (string-ascii 200))
)
  (let ((service-id (var-get next-service-id))
        (provider tx-sender))
    (asserts! (is-category-valid category) err-not-found)
    (asserts! (> price-per-hour u0) err-invalid-amount)
    
    (map-set services service-id {
      provider: provider,
      title: title,
      description: description,
      category: category,
      price-per-hour: price-per-hour,
      currency: currency,
      availability: availability,
      status: service-active,
      rating: u0,
      total-reviews: u0,
      created-at: stacks-block-height
    })
    
    ;; Update user profile
    (match (map-get? user-profiles provider)
      existing-profile (map-set user-profiles provider 
        (merge existing-profile {total-services: (+ (get total-services existing-profile) u1)}))
      (map-set user-profiles provider {
        name: "",
        bio: "",
        skills: "",
        total-services: u1,
        total-bookings: u0,
        average-rating: u0,
        is-verified: false,
        joined-at: stacks-block-height
      })
    )
    
    (var-set next-service-id (+ service-id u1))
    (ok service-id)
  )
)

;; Update service
(define-public (update-service 
  (service-id uint)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (price-per-hour uint)
  (availability (string-ascii 200))
  (status uint)
)
  (let ((service (unwrap! (map-get? services service-id) err-not-found)))
    (asserts! (is-eq (get provider service) tx-sender) err-unauthorized)
    (asserts! (> price-per-hour u0) err-invalid-amount)
    
    (map-set services service-id (merge service {
      title: title,
      description: description,
      price-per-hour: price-per-hour,
      availability: availability,
      status: status
    }))
    (ok true)
  )
)

;; Book a service
(define-public (book-service (service-id uint) (hours uint) (scheduled-time uint))
  (let ((service (unwrap! (map-get? services service-id) err-not-found))
        (booking-id (var-get next-booking-id))
        (client tx-sender)
        (total-amount (* (get price-per-hour service) hours))
        (platform-fee (calculate-platform-fee total-amount))
        (provider (get provider service)))
    
    (asserts! (is-eq (get status service) service-active) err-service-unavailable)
    (asserts! (> hours u0) err-invalid-amount)
    (asserts! (not (is-eq client provider)) err-unauthorized)
    
    ;; Check if client has sufficient balance (simplified check)
    (asserts! (>= (stx-get-balance client) (+ total-amount platform-fee)) err-insufficient-funds)
    
    ;; Transfer payment to escrow
    (try! (stx-transfer? (+ total-amount platform-fee) client (as-contract tx-sender)))
    (map-set escrow booking-id (+ total-amount platform-fee))
    
    (map-set bookings booking-id {
      service-id: service-id,
      client: client,
      provider: provider,
      hours: hours,
      total-amount: total-amount,
      platform-fee: platform-fee,
      status: booking-pending,
      scheduled-time: scheduled-time,
      created-at: stacks-block-height,
      completed-at: none
    })
    
    ;; Update user profile
    (match (map-get? user-profiles client)
      existing-profile (map-set user-profiles client 
        (merge existing-profile {total-bookings: (+ (get total-bookings existing-profile) u1)}))
      (map-set user-profiles client {
        name: "",
        bio: "",
        skills: "",
        total-services: u0,
        total-bookings: u1,
        average-rating: u0,
        is-verified: false,
        joined-at: stacks-block-height
      })
    )
    
    (var-set next-booking-id (+ booking-id u1))
    (ok booking-id)
  )
)

;; Confirm booking (by provider)
(define-public (confirm-booking (booking-id uint))
  (let ((booking (unwrap! (map-get? bookings booking-id) err-booking-not-found)))
    (asserts! (is-eq (get provider booking) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status booking) booking-pending) err-invalid-status)
    
    (map-set bookings booking-id (merge booking {status: booking-confirmed}))
    (ok true)
  )
)

;; Complete booking (by provider)
(define-public (complete-booking (booking-id uint))
  (let ((booking (unwrap! (map-get? bookings booking-id) err-booking-not-found)))
    (asserts! (is-eq (get provider booking) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status booking) booking-confirmed) err-invalid-status)
    
    (map-set bookings booking-id (merge booking {
      status: booking-completed,
      completed-at: (some stacks-block-height)
    }))
    (ok true)
  )
)

;; Release payment (by client after service completion)
(define-public (release-payment (booking-id uint))
  (let ((booking (unwrap! (map-get? bookings booking-id) err-booking-not-found))
        (escrow-amount (unwrap! (map-get? escrow booking-id) err-not-found)))
    
    (asserts! (is-eq (get client booking) tx-sender) err-unauthorized)
    (asserts! (is-eq (get status booking) booking-completed) err-invalid-status)
    
    ;; Transfer payment to provider
    (try! (as-contract (stx-transfer? (get total-amount booking) tx-sender (get provider booking))))
    ;; Transfer platform fee to contract owner
    (try! (as-contract (stx-transfer? (get platform-fee booking) tx-sender contract-owner)))
    
    ;; Remove from escrow
    (map-delete escrow booking-id)
    (ok true)
  )
)

;; Cancel booking
(define-public (cancel-booking (booking-id uint))
  (let ((booking (unwrap! (map-get? bookings booking-id) err-booking-not-found))
        (escrow-amount (unwrap! (map-get? escrow booking-id) err-not-found)))
    
    (asserts! (or (is-eq (get client booking) tx-sender) (is-eq (get provider booking) tx-sender)) err-unauthorized)
    (asserts! (or (is-eq (get status booking) booking-pending) (is-eq (get status booking) booking-confirmed)) err-invalid-status)
    
    ;; Refund client
    (try! (as-contract (stx-transfer? escrow-amount tx-sender (get client booking))))
    
    (map-set bookings booking-id (merge booking {status: booking-cancelled}))
    (map-delete escrow booking-id)
    (ok true)
  )
)

;; Add review
(define-public (add-review (booking-id uint) (rating uint) (comment (string-ascii 500)))
  (let ((booking (unwrap! (map-get? bookings booking-id) err-booking-not-found))
        (service-id (get service-id booking))
        (service (unwrap! (map-get? services service-id) err-not-found)))
    
    (asserts! (or (is-eq (get client booking) tx-sender) (is-eq (get provider booking) tx-sender)) err-unauthorized)
    (asserts! (is-eq (get status booking) booking-completed) err-invalid-status)
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-amount)
    (asserts! (is-none (map-get? reviews {booking-id: booking-id, reviewer: tx-sender})) err-already-reviewed)
    
    ;; Add review
    (map-set reviews {booking-id: booking-id, reviewer: tx-sender} {
      rating: rating,
      comment: comment,
      created-at: stacks-block-height
    })
    
    ;; Update service rating
    (let ((current-total (get total-reviews service))
          (current-rating (get rating service))
          (new-total (+ current-total u1))
          (new-rating (/ (+ (* current-rating current-total) rating) new-total)))
      
      (map-set services service-id (merge service {
        rating: new-rating,
        total-reviews: new-total
      }))
    )
    
    (ok true)
  )
)

;; Add new category (owner only)
(define-public (add-category (category (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set service-categories category true)
    (ok true)
  )
)

;; Update platform fee (owner only)
(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u1000) err-invalid-amount) ;; Max 10%
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)

;; Emergency functions (owner only)
(define-public (emergency-cancel-booking (booking-id uint))
  (let ((booking (unwrap! (map-get? bookings booking-id) err-booking-not-found))
        (escrow-amount (unwrap! (map-get? escrow booking-id) err-not-found)))
    
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    ;; Refund client
    (try! (as-contract (stx-transfer? escrow-amount tx-sender (get client booking))))
    
    (map-set bookings booking-id (merge booking {status: booking-cancelled}))
    (map-delete escrow booking-id)
    (ok true)
  )
)

;; Verify user (owner only)
(define-public (verify-user (user principal))
  (let ((profile (unwrap! (map-get? user-profiles user) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set user-profiles user (merge profile {is-verified: true}))
    (ok true)
  )
)