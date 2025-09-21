;; knowledge-exchange
;; Contract for facilitating skill exchanges and learning sessions between community members

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-exchange-not-found (err u101))
(define-constant err-session-not-found (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-already-enrolled (err u104))
(define-constant err-capacity-full (err u105))
(define-constant err-invalid-type (err u106))

;; Data Maps
(define-map skill-exchanges
  { exchange-id: uint }
  {
    teacher: principal,
    skill-id: uint,
    exchange-type: (string-utf8 30),
    title: (string-utf8 100),
    description: (string-utf8 1000),
    max-participants: uint,
    current-participants: uint,
    session-count: uint,
    start-date: uint,
    end-date: (optional uint),
    meeting-schedule: (string-utf8 300),
    location: (string-utf8 200),
    prerequisites: (optional (string-utf8 300)),
    materials-needed: (optional (string-utf8 500)),
    cost-per-participant: uint,
    exchange-rating: uint,
    rating-count: uint,
    status: (string-utf8 20),
    creation-date: uint
  }
)

(define-map exchange-sessions
  { session-id: uint }
  {
    exchange-id: uint,
    session-number: uint,
    session-date: uint,
    duration-minutes: uint,
    topic: (string-utf8 200),
    learning-objectives: (list 5 (string-utf8 200)),
    session-notes: (optional (string-utf8 1000)),
    attendance-count: uint,
    completion-status: (string-utf8 20),
    homework-assigned: (optional (string-utf8 500)),
    resources-shared: (list 10 (string-utf8 200))
  }
)

(define-map exchange-enrollments
  { enrollment-id: uint }
  {
    exchange-id: uint,
    participant: principal,
    enrollment-date: uint,
    payment-status: (string-utf8 20),
    completion-status: (string-utf8 20),
    attendance-rate: uint,
    progress-score: uint,
    participant-rating: (optional uint),
    feedback: (optional (string-utf8 1000)),
    certificate-earned: bool
  }
)

(define-map skill-swaps
  { swap-id: uint }
  {
    initiator: principal,
    responder: (optional principal),
    skill-offered: uint,
    skill-wanted: (string-utf8 100),
    swap-type: (string-utf8 30),
    estimated-hours: uint,
    meeting-preference: (string-utf8 200),
    status: (string-utf8 20),
    creation-date: uint,
    completion-date: (optional uint),
    mutual-rating: (optional { initiator-rating: uint, responder-rating: uint })
  }
)

(define-map learning-circles
  { circle-id: uint }
  {
    organizer: principal,
    circle-name: (string-utf8 100),
    focus-area: (string-utf8 100),
    description: (string-utf8 1000),
    member-count: uint,
    max-members: uint,
    meeting-frequency: (string-utf8 50),
    next-meeting: uint,
    location: (string-utf8 200),
    is-public: bool,
    creation-date: uint,
    activity-level: uint
  }
)

(define-map circle-memberships
  { membership-id: uint }
  {
    circle-id: uint,
    member: principal,
    join-date: uint,
    role: (string-utf8 30),
    contribution-score: uint,
    attendance-count: uint,
    is-active: bool
  }
)

;; Data Variables
(define-data-var next-exchange-id uint u1)
(define-data-var next-session-id uint u1)
(define-data-var next-enrollment-id uint u1)
(define-data-var next-swap-id uint u1)
(define-data-var next-circle-id uint u1)
(define-data-var next-membership-id uint u1)
(define-data-var total-exchanges uint u0)
(define-data-var total-sessions uint u0)
(define-data-var total-swaps uint u0)
(define-data-var total-circles uint u0)

;; Private Functions
(define-private (is-valid-exchange-type (exchange-type (string-utf8 30)))
  (or (is-eq exchange-type u"workshop")
      (is-eq exchange-type u"course")
      (is-eq exchange-type u"mentorship")
      (is-eq exchange-type u"practice-group")
      (is-eq exchange-type u"study-group")
      (is-eq exchange-type u"skill-share"))
)

(define-private (is-valid-swap-type (swap-type (string-utf8 30)))
  (or (is-eq swap-type u"one-time")
      (is-eq swap-type u"ongoing")
      (is-eq swap-type u"project-based")
      (is-eq swap-type u"mentorship-trade"))
)

(define-private (is-valid-status (status (string-utf8 20)))
  (or (is-eq status u"open")
      (is-eq status u"in-progress")
      (is-eq status u"completed")
      (is-eq status u"cancelled")
      (is-eq status u"paused"))
)

;; Public Functions
(define-public (create-skill-exchange
    (skill-id uint)
    (exchange-type (string-utf8 30))
    (title (string-utf8 100))
    (description (string-utf8 1000))
    (max-participants uint)
    (session-count uint)
    (start-date uint)
    (meeting-schedule (string-utf8 300))
    (location (string-utf8 200))
    (prerequisites (optional (string-utf8 300)))
    (materials-needed (optional (string-utf8 500)))
    (cost-per-participant uint)
  )
  (let
    (
      (exchange-id (var-get next-exchange-id))
    )
    (asserts! (is-valid-exchange-type exchange-type) err-invalid-type)
    (asserts! (> max-participants u0) (err u107))
    (asserts! (> session-count u0) (err u108))
    (asserts! (> start-date block-height) (err u109))
    
    (map-set skill-exchanges
      { exchange-id: exchange-id }
      {
        teacher: tx-sender,
        skill-id: skill-id,
        exchange-type: exchange-type,
        title: title,
        description: description,
        max-participants: max-participants,
        current-participants: u0,
        session-count: session-count,
        start-date: start-date,
        end-date: none,
        meeting-schedule: meeting-schedule,
        location: location,
        prerequisites: prerequisites,
        materials-needed: materials-needed,
        cost-per-participant: cost-per-participant,
        exchange-rating: u0,
        rating-count: u0,
        status: u"open",
        creation-date: block-height
      }
    )
    
    (var-set next-exchange-id (+ exchange-id u1))
    (var-set total-exchanges (+ (var-get total-exchanges) u1))
    
    (ok exchange-id)
  )
)

(define-public (enroll-in-exchange (exchange-id uint))
  (let
    (
      (exchange-info (unwrap! (map-get? skill-exchanges { exchange-id: exchange-id }) err-exchange-not-found))
      (enrollment-id (var-get next-enrollment-id))
    )
    (asserts! (is-eq (get status exchange-info) u"open") (err u110))
    (asserts! (< (get current-participants exchange-info) (get max-participants exchange-info)) err-capacity-full)
    (asserts! (not (is-eq tx-sender (get teacher exchange-info))) (err u111))
    
    ;; Create enrollment
    (map-set exchange-enrollments
      { enrollment-id: enrollment-id }
      {
        exchange-id: exchange-id,
        participant: tx-sender,
        enrollment-date: block-height,
        payment-status: u"pending",
        completion-status: u"enrolled",
        attendance-rate: u0,
        progress-score: u0,
        participant-rating: none,
        feedback: none,
        certificate-earned: false
      }
    )
    
    ;; Update exchange participant count
    (map-set skill-exchanges
      { exchange-id: exchange-id }
      (merge exchange-info {
        current-participants: (+ (get current-participants exchange-info) u1)
      })
    )
    
    (var-set next-enrollment-id (+ enrollment-id u1))
    (ok enrollment-id)
  )
)

(define-public (create-session
    (exchange-id uint)
    (session-number uint)
    (session-date uint)
    (duration-minutes uint)
    (topic (string-utf8 200))
    (learning-objectives (list 5 (string-utf8 200)))
    (homework-assigned (optional (string-utf8 500)))
  )
  (let
    (
      (exchange-info (unwrap! (map-get? skill-exchanges { exchange-id: exchange-id }) err-exchange-not-found))
      (session-id (var-get next-session-id))
    )
    (asserts! (is-eq tx-sender (get teacher exchange-info)) err-unauthorized)
    (asserts! (> duration-minutes u0) (err u112))
    
    (map-set exchange-sessions
      { session-id: session-id }
      {
        exchange-id: exchange-id,
        session-number: session-number,
        session-date: session-date,
        duration-minutes: duration-minutes,
        topic: topic,
        learning-objectives: learning-objectives,
        session-notes: none,
        attendance-count: u0,
        completion-status: u"scheduled",
        homework-assigned: homework-assigned,
        resources-shared: (list)
      }
    )
    
    (var-set next-session-id (+ session-id u1))
    (var-set total-sessions (+ (var-get total-sessions) u1))
    
    (ok session-id)
  )
)

(define-public (initiate-skill-swap
    (skill-offered uint)
    (skill-wanted (string-utf8 100))
    (swap-type (string-utf8 30))
    (estimated-hours uint)
    (meeting-preference (string-utf8 200))
  )
  (let
    (
      (swap-id (var-get next-swap-id))
    )
    (asserts! (is-valid-swap-type swap-type) err-invalid-type)
    (asserts! (> estimated-hours u0) (err u113))
    
    (map-set skill-swaps
      { swap-id: swap-id }
      {
        initiator: tx-sender,
        responder: none,
        skill-offered: skill-offered,
        skill-wanted: skill-wanted,
        swap-type: swap-type,
        estimated-hours: estimated-hours,
        meeting-preference: meeting-preference,
        status: u"open",
        creation-date: block-height,
        completion-date: none,
        mutual-rating: none
      }
    )
    
    (var-set next-swap-id (+ swap-id u1))
    (var-set total-swaps (+ (var-get total-swaps) u1))
    
    (ok swap-id)
  )
)

(define-public (respond-to-swap (swap-id uint) (accept bool))
  (let
    (
      (swap-info (unwrap! (map-get? skill-swaps { swap-id: swap-id }) (err u114)))
    )
    (asserts! (is-eq (get status swap-info) u"open") (err u115))
    (asserts! (not (is-eq tx-sender (get initiator swap-info))) (err u116))
    
    (if accept
      (map-set skill-swaps
        { swap-id: swap-id }
        (merge swap-info {
          responder: (some tx-sender),
          status: u"in-progress"
        })
      )
      (map-set skill-swaps
        { swap-id: swap-id }
        (merge swap-info { status: u"cancelled" })
      )
    )
    
    (ok accept)
  )
)

(define-public (create-learning-circle
    (circle-name (string-utf8 100))
    (focus-area (string-utf8 100))
    (description (string-utf8 1000))
    (max-members uint)
    (meeting-frequency (string-utf8 50))
    (next-meeting uint)
    (location (string-utf8 200))
    (is-public bool)
  )
  (let
    (
      (circle-id (var-get next-circle-id))
      (membership-id (var-get next-membership-id))
    )
    (asserts! (> max-members u0) (err u117))
    (asserts! (> next-meeting block-height) (err u118))
    
    ;; Create learning circle
    (map-set learning-circles
      { circle-id: circle-id }
      {
        organizer: tx-sender,
        circle-name: circle-name,
        focus-area: focus-area,
        description: description,
        member-count: u1,
        max-members: max-members,
        meeting-frequency: meeting-frequency,
        next-meeting: next-meeting,
        location: location,
        is-public: is-public,
        creation-date: block-height,
        activity-level: u1
      }
    )
    
    ;; Auto-enroll organizer as member
    (map-set circle-memberships
      { membership-id: membership-id }
      {
        circle-id: circle-id,
        member: tx-sender,
        join-date: block-height,
        role: u"organizer",
        contribution-score: u1,
        attendance-count: u0,
        is-active: true
      }
    )
    
    (var-set next-circle-id (+ circle-id u1))
    (var-set next-membership-id (+ membership-id u1))
    (var-set total-circles (+ (var-get total-circles) u1))
    
    (ok circle-id)
  )
)

(define-public (join-learning-circle (circle-id uint))
  (let
    (
      (circle-info (unwrap! (map-get? learning-circles { circle-id: circle-id }) (err u119)))
      (membership-id (var-get next-membership-id))
    )
    (asserts! (get is-public circle-info) (err u120))
    (asserts! (< (get member-count circle-info) (get max-members circle-info)) err-capacity-full)
    
    ;; Create membership
    (map-set circle-memberships
      { membership-id: membership-id }
      {
        circle-id: circle-id,
        member: tx-sender,
        join-date: block-height,
        role: u"member",
        contribution-score: u0,
        attendance-count: u0,
        is-active: true
      }
    )
    
    ;; Update member count
    (map-set learning-circles
      { circle-id: circle-id }
      (merge circle-info {
        member-count: (+ (get member-count circle-info) u1)
      })
    )
    
    (var-set next-membership-id (+ membership-id u1))
    (ok membership-id)
  )
)

(define-public (rate-exchange (enrollment-id uint) (rating uint) (feedback (string-utf8 1000)))
  (let
    (
      (enrollment (unwrap! (map-get? exchange-enrollments { enrollment-id: enrollment-id }) (err u121)))
      (exchange-info (unwrap! (map-get? skill-exchanges { exchange-id: (get exchange-id enrollment) }) err-exchange-not-found))
      (current-rating (get exchange-rating exchange-info))
      (rating-count (get rating-count exchange-info))
      (new-rating-count (+ rating-count u1))
      (new-average (/ (+ (* current-rating rating-count) rating) new-rating-count))
    )
    (asserts! (is-eq tx-sender (get participant enrollment)) err-unauthorized)
    (asserts! (is-eq (get completion-status enrollment) u"completed") (err u122))
    (asserts! (and (>= rating u1) (<= rating u5)) (err u123))
    
    ;; Update enrollment with rating
    (map-set exchange-enrollments
      { enrollment-id: enrollment-id }
      (merge enrollment {
        participant-rating: (some rating),
        feedback: (some feedback)
      })
    )
    
    ;; Update exchange rating
    (map-set skill-exchanges
      { exchange-id: (get exchange-id enrollment) }
      (merge exchange-info {
        exchange-rating: new-average,
        rating-count: new-rating-count
      })
    )
    
    (ok true)
  )
)

;; Read Functions
(define-read-only (get-skill-exchange (exchange-id uint))
  (map-get? skill-exchanges { exchange-id: exchange-id })
)

(define-read-only (get-exchange-session (session-id uint))
  (map-get? exchange-sessions { session-id: session-id })
)

(define-read-only (get-enrollment (enrollment-id uint))
  (map-get? exchange-enrollments { enrollment-id: enrollment-id })
)

(define-read-only (get-skill-swap (swap-id uint))
  (map-get? skill-swaps { swap-id: swap-id })
)

(define-read-only (get-learning-circle (circle-id uint))
  (map-get? learning-circles { circle-id: circle-id })
)

(define-read-only (get-circle-membership (membership-id uint))
  (map-get? circle-memberships { membership-id: membership-id })
)

(define-read-only (get-exchange-stats)
  {
    total-exchanges: (var-get total-exchanges),
    total-sessions: (var-get total-sessions),
    total-swaps: (var-get total-swaps),
    total-circles: (var-get total-circles),
    next-exchange-id: (var-get next-exchange-id),
    next-session-id: (var-get next-session-id),
    next-enrollment-id: (var-get next-enrollment-id),
    next-swap-id: (var-get next-swap-id),
    next-circle-id: (var-get next-circle-id),
    next-membership-id: (var-get next-membership-id)
  }
)

