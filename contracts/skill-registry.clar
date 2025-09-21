;; skill-registry
;; Contract for managing neighborhood skill registration and talent discovery

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-skill-not-found (err u101))
(define-constant err-invalid-level (err u102))
(define-constant err-invalid-category (err u103))
(define-constant err-already-registered (err u104))
(define-constant err-user-not-found (err u105))

;; Data Maps
(define-map skill-providers
  { provider: principal }
  {
    name: (string-utf8 100),
    bio: (string-utf8 500),
    contact-info: (string-utf8 200),
    location: (string-utf8 100),
    availability: (string-utf8 200),
    total-skills: uint,
    average-rating: uint,
    total-ratings: uint,
    sessions-taught: uint,
    sessions-learned: uint,
    registration-date: uint,
    is-active: bool
  }
)

(define-map skills
  { skill-id: uint }
  {
    provider: principal,
    skill-name: (string-utf8 100),
    category: (string-utf8 50),
    description: (string-utf8 1000),
    proficiency-level: (string-utf8 20),
    years-experience: uint,
    certifications: (list 5 (string-utf8 200)),
    teaching-methods: (list 10 (string-utf8 100)),
    prerequisites: (optional (string-utf8 300)),
    max-students: uint,
    session-duration: uint,
    cost-per-session: uint,
    equipment-needed: (optional (string-utf8 300)),
    skill-rating: uint,
    skill-rating-count: uint,
    creation-date: uint,
    is-available: bool
  }
)

(define-map skill-categories
  { category: (string-utf8 50) }
  {
    description: (string-utf8 300),
    skill-count: uint,
    total-providers: uint,
    popularity-score: uint
  }
)

(define-map user-skills
  { user: principal }
  { skill-ids: (list 50 uint) }
)

(define-map skill-endorsements
  { endorsement-id: uint }
  {
    skill-id: uint,
    endorser: principal,
    endorsement-text: (string-utf8 500),
    credibility-score: uint,
    endorsement-date: uint
  }
)

(define-map skill-requests
  { request-id: uint }
  {
    requester: principal,
    skill-wanted: (string-utf8 100),
    category: (string-utf8 50),
    description: (string-utf8 500),
    max-budget: uint,
    preferred-schedule: (string-utf8 200),
    location-preference: (string-utf8 100),
    urgency-level: (string-utf8 20),
    request-date: uint,
    status: (string-utf8 20),
    matched-skills: (list 10 uint)
  }
)

;; Data Variables
(define-data-var next-skill-id uint u1)
(define-data-var next-endorsement-id uint u1)
(define-data-var next-request-id uint u1)
(define-data-var total-skills uint u0)
(define-data-var total-providers uint u0)
(define-data-var total-categories uint u0)
(define-data-var total-requests uint u0)

;; Private Functions
(define-private (is-valid-proficiency (level (string-utf8 20)))
  (or (is-eq level u"beginner")
      (is-eq level u"intermediate")
      (is-eq level u"advanced")
      (is-eq level u"expert")
      (is-eq level u"master"))
)

(define-private (is-valid-category (category (string-utf8 50)))
  (or (is-eq category u"technical-skills")
      (is-eq category u"creative-arts")
      (is-eq category u"home-improvement")
      (is-eq category u"cooking-baking")
      (is-eq category u"gardening-farming")
      (is-eq category u"health-wellness")
      (is-eq category u"business-finance")
      (is-eq category u"languages")
      (is-eq category u"music-performance")
      (is-eq category u"sports-fitness")
      (is-eq category u"crafts-hobbies")
      (is-eq category u"childcare-education")
      (is-eq category u"senior-care")
      (is-eq category u"pet-care")
      (is-eq category u"other"))
)

(define-private (is-valid-urgency (urgency (string-utf8 20)))
  (or (is-eq urgency u"low")
      (is-eq urgency u"medium")
      (is-eq urgency u"high")
      (is-eq urgency u"urgent"))
)

;; Public Functions
(define-public (register-skill-provider
    (name (string-utf8 100))
    (bio (string-utf8 500))
    (contact-info (string-utf8 200))
    (location (string-utf8 100))
    (availability (string-utf8 200))
  )
  (begin
    (asserts! (is-none (map-get? skill-providers { provider: tx-sender })) err-already-registered)
    
    (map-set skill-providers
      { provider: tx-sender }
      {
        name: name,
        bio: bio,
        contact-info: contact-info,
        location: location,
        availability: availability,
        total-skills: u0,
        average-rating: u0,
        total-ratings: u0,
        sessions-taught: u0,
        sessions-learned: u0,
        registration-date: block-height,
        is-active: true
      }
    )
    
    (var-set total-providers (+ (var-get total-providers) u1))
    (ok true)
  )
)

(define-public (register-skill
    (skill-name (string-utf8 100))
    (category (string-utf8 50))
    (description (string-utf8 1000))
    (proficiency-level (string-utf8 20))
    (years-experience uint)
    (certifications (list 5 (string-utf8 200)))
    (teaching-methods (list 10 (string-utf8 100)))
    (prerequisites (optional (string-utf8 300)))
    (max-students uint)
    (session-duration uint)
    (cost-per-session uint)
    (equipment-needed (optional (string-utf8 300)))
  )
  (let
    (
      (skill-id (var-get next-skill-id))
      (provider-info (unwrap! (map-get? skill-providers { provider: tx-sender }) err-user-not-found))
      (current-skills (default-to { skill-ids: (list) }
        (map-get? user-skills { user: tx-sender })))
    )
    (asserts! (is-valid-proficiency proficiency-level) err-invalid-level)
    (asserts! (is-valid-category category) err-invalid-category)
    (asserts! (> max-students u0) (err u106))
    (asserts! (> session-duration u0) (err u107))
    
    ;; Register skill
    (map-set skills
      { skill-id: skill-id }
      {
        provider: tx-sender,
        skill-name: skill-name,
        category: category,
        description: description,
        proficiency-level: proficiency-level,
        years-experience: years-experience,
        certifications: certifications,
        teaching-methods: teaching-methods,
        prerequisites: prerequisites,
        max-students: max-students,
        session-duration: session-duration,
        cost-per-session: cost-per-session,
        equipment-needed: equipment-needed,
        skill-rating: u0,
        skill-rating-count: u0,
        creation-date: block-height,
        is-available: true
      }
    )
    
    ;; Update user skills list
    (map-set user-skills
      { user: tx-sender }
      { skill-ids: (unwrap! (as-max-len?
          (append (get skill-ids current-skills) skill-id) u50)
        (err u108)) }
    )
    
    ;; Update provider skill count
    (map-set skill-providers
      { provider: tx-sender }
      (merge provider-info { total-skills: (+ (get total-skills provider-info) u1) })
    )
    
    ;; Update category stats
    (let
      (
        (category-info (default-to {
          description: u"Community skill category",
          skill-count: u0,
          total-providers: u0,
          popularity-score: u0
        } (map-get? skill-categories { category: category })))
      )
      (map-set skill-categories
        { category: category }
        (merge category-info {
          skill-count: (+ (get skill-count category-info) u1),
          total-providers: (+ (get total-providers category-info) u1),
          popularity-score: (+ (get popularity-score category-info) u1)
        })
      )
    )
    
    ;; Update counters
    (var-set next-skill-id (+ skill-id u1))
    (var-set total-skills (+ (var-get total-skills) u1))
    
    (ok skill-id)
  )
)

(define-public (create-skill-request
    (skill-wanted (string-utf8 100))
    (category (string-utf8 50))
    (description (string-utf8 500))
    (max-budget uint)
    (preferred-schedule (string-utf8 200))
    (location-preference (string-utf8 100))
    (urgency-level (string-utf8 20))
  )
  (let
    (
      (request-id (var-get next-request-id))
    )
    (asserts! (is-valid-category category) err-invalid-category)
    (asserts! (is-valid-urgency urgency-level) (err u109))
    
    (map-set skill-requests
      { request-id: request-id }
      {
        requester: tx-sender,
        skill-wanted: skill-wanted,
        category: category,
        description: description,
        max-budget: max-budget,
        preferred-schedule: preferred-schedule,
        location-preference: location-preference,
        urgency-level: urgency-level,
        request-date: block-height,
        status: u"open",
        matched-skills: (list)
      }
    )
    
    (var-set next-request-id (+ request-id u1))
    (var-set total-requests (+ (var-get total-requests) u1))
    
    (ok request-id)
  )
)

(define-public (endorse-skill
    (skill-id uint)
    (endorsement-text (string-utf8 500))
    (credibility-score uint)
  )
  (let
    (
      (endorsement-id (var-get next-endorsement-id))
      (skill-info (unwrap! (map-get? skills { skill-id: skill-id }) err-skill-not-found))
    )
    (asserts! (not (is-eq tx-sender (get provider skill-info))) (err u110))
    (asserts! (and (>= credibility-score u1) (<= credibility-score u10)) (err u111))
    
    (map-set skill-endorsements
      { endorsement-id: endorsement-id }
      {
        skill-id: skill-id,
        endorser: tx-sender,
        endorsement-text: endorsement-text,
        credibility-score: credibility-score,
        endorsement-date: block-height
      }
    )
    
    (var-set next-endorsement-id (+ endorsement-id u1))
    (ok endorsement-id)
  )
)

(define-public (rate-skill
    (skill-id uint)
    (rating uint)
  )
  (let
    (
      (skill-info (unwrap! (map-get? skills { skill-id: skill-id }) err-skill-not-found))
      (current-rating (get skill-rating skill-info))
      (rating-count (get skill-rating-count skill-info))
      (new-rating-count (+ rating-count u1))
      (new-average-rating (/ (+ (* current-rating rating-count) rating) new-rating-count))
    )
    (asserts! (not (is-eq tx-sender (get provider skill-info))) (err u112))
    (asserts! (and (>= rating u1) (<= rating u5)) (err u113))
    
    ;; Update skill rating
    (map-set skills
      { skill-id: skill-id }
      (merge skill-info {
        skill-rating: new-average-rating,
        skill-rating-count: new-rating-count
      })
    )
    
    (ok true)
  )
)

(define-public (update-skill-availability (skill-id uint) (is-available bool))
  (let
    (
      (skill-info (unwrap! (map-get? skills { skill-id: skill-id }) err-skill-not-found))
    )
    (asserts! (is-eq tx-sender (get provider skill-info)) err-unauthorized)
    
    (map-set skills
      { skill-id: skill-id }
      (merge skill-info { is-available: is-available })
    )
    
    (ok true)
  )
)

(define-public (update-provider-profile
    (name (string-utf8 100))
    (bio (string-utf8 500))
    (contact-info (string-utf8 200))
    (availability (string-utf8 200))
  )
  (let
    (
      (provider-info (unwrap! (map-get? skill-providers { provider: tx-sender }) err-user-not-found))
    )
    (map-set skill-providers
      { provider: tx-sender }
      (merge provider-info {
        name: name,
        bio: bio,
        contact-info: contact-info,
        availability: availability
      })
    )
    
    (ok true)
  )
)

;; Read Functions
(define-read-only (get-skill-provider (provider principal))
  (map-get? skill-providers { provider: provider })
)

(define-read-only (get-skill (skill-id uint))
  (map-get? skills { skill-id: skill-id })
)

(define-read-only (get-skill-category (category (string-utf8 50)))
  (map-get? skill-categories { category: category })
)

(define-read-only (get-user-skills (user principal))
  (map-get? user-skills { user: user })
)

(define-read-only (get-skill-endorsement (endorsement-id uint))
  (map-get? skill-endorsements { endorsement-id: endorsement-id })
)

(define-read-only (get-skill-request (request-id uint))
  (map-get? skill-requests { request-id: request-id })
)

(define-read-only (get-registry-stats)
  {
    total-skills: (var-get total-skills),
    total-providers: (var-get total-providers),
    total-categories: (var-get total-categories),
    total-requests: (var-get total-requests),
    next-skill-id: (var-get next-skill-id),
    next-endorsement-id: (var-get next-endorsement-id),
    next-request-id: (var-get next-request-id)
  }
)

