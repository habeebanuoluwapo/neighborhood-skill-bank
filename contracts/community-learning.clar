;; community-learning
;; Contract for managing community learning paths, achievements, and skill development tracking

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-path-not-found (err u101))
(define-constant err-achievement-not-found (err u102))
(define-constant err-invalid-level (err u103))
(define-constant err-already-enrolled (err u104))
(define-constant err-prerequisite-not-met (err u105))
(define-constant err-invalid-badge-type (err u106))

;; Data Maps
(define-map learning-paths
  { path-id: uint }
  {
    creator: principal,
    path-name: (string-utf8 100),
    description: (string-utf8 1000),
    category: (string-utf8 50),
    difficulty-level: (string-utf8 20),
    estimated-duration: uint,
    prerequisites: (list 5 uint),
    skills-covered: (list 20 uint),
    milestones: (list 10 (string-utf8 200)),
    completion-criteria: (string-utf8 500),
    total-enrollments: uint,
    completion-rate: uint,
    average-rating: uint,
    rating-count: uint,
    is-public: bool,
    creation-date: uint
  }
)

(define-map learner-progress
  { progress-id: uint }
  {
    learner: principal,
    path-id: uint,
    enrollment-date: uint,
    current-milestone: uint,
    completion-percentage: uint,
    skills-acquired: (list 20 uint),
    time-invested: uint,
    last-activity: uint,
    status: (string-utf8 20),
    mentor-assigned: (optional principal),
    notes: (optional (string-utf8 1000))
  }
)

(define-map skill-achievements
  { achievement-id: uint }
  {
    learner: principal,
    skill-id: uint,
    achievement-type: (string-utf8 30),
    description: (string-utf8 300),
    evidence-provided: (optional (string-utf8 500)),
    verification-status: (string-utf8 20),
    verifier: (optional principal),
    achievement-date: uint,
    badge-earned: (optional (string-utf8 50))
  }
)

(define-map community-badges
  { badge-id: uint }
  {
    badge-name: (string-utf8 100),
    badge-type: (string-utf8 30),
    description: (string-utf8 300),
    requirements: (string-utf8 500),
    badge-image-hash: (optional (string-utf8 64)),
    rarity-level: (string-utf8 20),
    total-earned: uint,
    creation-date: uint
  }
)

(define-map learner-badges
  { learner: principal, badge-id: uint }
  {
    earned-date: uint,
    verification-status: (string-utf8 20),
    showcase-permission: bool
  }
)

(define-map skill-assessments
  { assessment-id: uint }
  {
    assessor: principal,
    learner: principal,
    skill-id: uint,
    assessment-type: (string-utf8 30),
    score: uint,
    max-score: uint,
    feedback: (string-utf8 1000),
    improvement-areas: (list 5 (string-utf8 200)),
    strengths: (list 5 (string-utf8 200)),
    assessment-date: uint,
    follow-up-required: bool
  }
)

(define-map learning-resources
  { resource-id: uint }
  {
    contributor: principal,
    title: (string-utf8 200),
    description: (string-utf8 500),
    resource-type: (string-utf8 30),
    skill-tags: (list 10 uint),
    difficulty-level: (string-utf8 20),
    content-hash: (string-utf8 64),
    access-level: (string-utf8 20),
    usage-count: uint,
    rating: uint,
    rating-count: uint,
    creation-date: uint
  }
)

;; Data Variables
(define-data-var next-path-id uint u1)
(define-data-var next-progress-id uint u1)
(define-data-var next-achievement-id uint u1)
(define-data-var next-badge-id uint u1)
(define-data-var next-assessment-id uint u1)
(define-data-var next-resource-id uint u1)
(define-data-var total-paths uint u0)
(define-data-var total-learners uint u0)
(define-data-var total-achievements uint u0)
(define-data-var total-badges-earned uint u0)

;; Private Functions
(define-private (is-valid-difficulty (level (string-utf8 20)))
  (or (is-eq level u"beginner")
      (is-eq level u"intermediate")
      (is-eq level u"advanced")
      (is-eq level u"expert"))
)

(define-private (is-valid-badge-type (badge-type (string-utf8 30)))
  (or (is-eq badge-type u"skill-mastery")
      (is-eq badge-type u"completion")
      (is-eq badge-type u"innovation")
      (is-eq badge-type u"community-contribution")
      (is-eq badge-type u"mentorship")
      (is-eq badge-type u"collaboration"))
)

(define-private (is-valid-assessment-type (assessment-type (string-utf8 30)))
  (or (is-eq assessment-type u"practical")
      (is-eq assessment-type u"theoretical")
      (is-eq assessment-type u"project-based")
      (is-eq assessment-type u"peer-review")
      (is-eq assessment-type u"self-assessment"))
)

;; Public Functions
(define-public (create-learning-path
    (path-name (string-utf8 100))
    (description (string-utf8 1000))
    (category (string-utf8 50))
    (difficulty-level (string-utf8 20))
    (estimated-duration uint)
    (prerequisites (list 5 uint))
    (skills-covered (list 20 uint))
    (milestones (list 10 (string-utf8 200)))
    (completion-criteria (string-utf8 500))
    (is-public bool)
  )
  (let
    (
      (path-id (var-get next-path-id))
    )
    (asserts! (is-valid-difficulty difficulty-level) err-invalid-level)
    (asserts! (> estimated-duration u0) (err u107))
    (asserts! (> (len skills-covered) u0) (err u108))
    
    (map-set learning-paths
      { path-id: path-id }
      {
        creator: tx-sender,
        path-name: path-name,
        description: description,
        category: category,
        difficulty-level: difficulty-level,
        estimated-duration: estimated-duration,
        prerequisites: prerequisites,
        skills-covered: skills-covered,
        milestones: milestones,
        completion-criteria: completion-criteria,
        total-enrollments: u0,
        completion-rate: u0,
        average-rating: u0,
        rating-count: u0,
        is-public: is-public,
        creation-date: block-height
      }
    )
    
    (var-set next-path-id (+ path-id u1))
    (var-set total-paths (+ (var-get total-paths) u1))
    
    (ok path-id)
  )
)

(define-public (enroll-in-path (path-id uint))
  (let
    (
      (path-info (unwrap! (map-get? learning-paths { path-id: path-id }) err-path-not-found))
      (progress-id (var-get next-progress-id))
    )
    (asserts! (or (get is-public path-info)
                  (is-eq tx-sender (get creator path-info))) (err u109))
    
    (map-set learner-progress
      { progress-id: progress-id }
      {
        learner: tx-sender,
        path-id: path-id,
        enrollment-date: block-height,
        current-milestone: u0,
        completion-percentage: u0,
        skills-acquired: (list),
        time-invested: u0,
        last-activity: block-height,
        status: u"active",
        mentor-assigned: none,
        notes: none
      }
    )
    
    ;; Update path enrollment count
    (map-set learning-paths
      { path-id: path-id }
      (merge path-info {
        total-enrollments: (+ (get total-enrollments path-info) u1)
      })
    )
    
    (var-set next-progress-id (+ progress-id u1))
    (ok progress-id)
  )
)

(define-public (record-skill-achievement
    (learner principal)
    (skill-id uint)
    (achievement-type (string-utf8 30))
    (description (string-utf8 300))
    (evidence-provided (optional (string-utf8 500)))
  )
  (let
    (
      (achievement-id (var-get next-achievement-id))
    )
    ;; Allow self-recording or verification by others
    (asserts! (or (is-eq tx-sender learner)
                  (is-eq tx-sender contract-owner)) (err u110))
    
    (map-set skill-achievements
      { achievement-id: achievement-id }
      {
        learner: learner,
        skill-id: skill-id,
        achievement-type: achievement-type,
        description: description,
        evidence-provided: evidence-provided,
        verification-status: u"pending",
        verifier: none,
        achievement-date: block-height,
        badge-earned: none
      }
    )
    
    (var-set next-achievement-id (+ achievement-id u1))
    (var-set total-achievements (+ (var-get total-achievements) u1))
    
    (ok achievement-id)
  )
)

(define-public (create-community-badge
    (badge-name (string-utf8 100))
    (badge-type (string-utf8 30))
    (description (string-utf8 300))
    (requirements (string-utf8 500))
    (badge-image-hash (optional (string-utf8 64)))
    (rarity-level (string-utf8 20))
  )
  (let
    (
      (badge-id (var-get next-badge-id))
    )
    (asserts! (is-valid-badge-type badge-type) err-invalid-badge-type)
    (asserts! (or (is-eq rarity-level u"common")
                  (is-eq rarity-level u"uncommon")
                  (is-eq rarity-level u"rare")
                  (is-eq rarity-level u"legendary")) (err u111))
    
    (map-set community-badges
      { badge-id: badge-id }
      {
        badge-name: badge-name,
        badge-type: badge-type,
        description: description,
        requirements: requirements,
        badge-image-hash: badge-image-hash,
        rarity-level: rarity-level,
        total-earned: u0,
        creation-date: block-height
      }
    )
    
    (var-set next-badge-id (+ badge-id u1))
    (ok badge-id)
  )
)

(define-public (award-badge (learner principal) (badge-id uint) (showcase-permission bool))
  (let
    (
      (badge-info (unwrap! (map-get? community-badges { badge-id: badge-id }) (err u112)))
    )
    (asserts! (or (is-eq tx-sender contract-owner)
                  (is-eq tx-sender learner)) (err u113))
    
    ;; Award badge to learner
    (map-set learner-badges
      { learner: learner, badge-id: badge-id }
      {
        earned-date: block-height,
        verification-status: u"verified",
        showcase-permission: showcase-permission
      }
    )
    
    ;; Update badge total earned count
    (map-set community-badges
      { badge-id: badge-id }
      (merge badge-info {
        total-earned: (+ (get total-earned badge-info) u1)
      })
    )
    
    (var-set total-badges-earned (+ (var-get total-badges-earned) u1))
    (ok true)
  )
)

(define-public (conduct-skill-assessment
    (learner principal)
    (skill-id uint)
    (assessment-type (string-utf8 30))
    (score uint)
    (max-score uint)
    (feedback (string-utf8 1000))
    (improvement-areas (list 5 (string-utf8 200)))
    (strengths (list 5 (string-utf8 200)))
    (follow-up-required bool)
  )
  (let
    (
      (assessment-id (var-get next-assessment-id))
    )
    (asserts! (is-valid-assessment-type assessment-type) (err u114))
    (asserts! (<= score max-score) (err u115))
    (asserts! (> max-score u0) (err u116))
    
    (map-set skill-assessments
      { assessment-id: assessment-id }
      {
        assessor: tx-sender,
        learner: learner,
        skill-id: skill-id,
        assessment-type: assessment-type,
        score: score,
        max-score: max-score,
        feedback: feedback,
        improvement-areas: improvement-areas,
        strengths: strengths,
        assessment-date: block-height,
        follow-up-required: follow-up-required
      }
    )
    
    (var-set next-assessment-id (+ assessment-id u1))
    (ok assessment-id)
  )
)

(define-public (add-learning-resource
    (title (string-utf8 200))
    (description (string-utf8 500))
    (resource-type (string-utf8 30))
    (skill-tags (list 10 uint))
    (difficulty-level (string-utf8 20))
    (content-hash (string-utf8 64))
    (access-level (string-utf8 20))
  )
  (let
    (
      (resource-id (var-get next-resource-id))
    )
    (asserts! (is-valid-difficulty difficulty-level) err-invalid-level)
    (asserts! (or (is-eq access-level u"public")
                  (is-eq access-level u"member-only")
                  (is-eq access-level u"premium")) (err u117))
    
    (map-set learning-resources
      { resource-id: resource-id }
      {
        contributor: tx-sender,
        title: title,
        description: description,
        resource-type: resource-type,
        skill-tags: skill-tags,
        difficulty-level: difficulty-level,
        content-hash: content-hash,
        access-level: access-level,
        usage-count: u0,
        rating: u0,
        rating-count: u0,
        creation-date: block-height
      }
    )
    
    (var-set next-resource-id (+ resource-id u1))
    (ok resource-id)
  )
)

(define-public (update-learning-progress
    (progress-id uint)
    (current-milestone uint)
    (completion-percentage uint)
    (skills-acquired (list 20 uint))
    (time-invested uint)
    (notes (string-utf8 1000))
  )
  (let
    (
      (progress-info (unwrap! (map-get? learner-progress { progress-id: progress-id }) (err u118)))
    )
    (asserts! (is-eq tx-sender (get learner progress-info)) err-unauthorized)
    (asserts! (<= completion-percentage u100) (err u119))
    
    (map-set learner-progress
      { progress-id: progress-id }
      (merge progress-info {
        current-milestone: current-milestone,
        completion-percentage: completion-percentage,
        skills-acquired: skills-acquired,
        time-invested: time-invested,
        last-activity: block-height,
        notes: (some notes)
      })
    )
    
    (ok true)
  )
)

(define-public (rate-learning-resource (resource-id uint) (rating uint))
  (let
    (
      (resource-info (unwrap! (map-get? learning-resources { resource-id: resource-id }) (err u120)))
      (current-rating (get rating resource-info))
      (rating-count (get rating-count resource-info))
      (new-rating-count (+ rating-count u1))
      (new-average (/ (+ (* current-rating rating-count) rating) new-rating-count))
    )
    (asserts! (and (>= rating u1) (<= rating u5)) (err u121))
    
    (map-set learning-resources
      { resource-id: resource-id }
      (merge resource-info {
        rating: new-average,
        rating-count: new-rating-count,
        usage-count: (+ (get usage-count resource-info) u1)
      })
    )
    
    (ok true)
  )
)

;; Read Functions
(define-read-only (get-learning-path (path-id uint))
  (map-get? learning-paths { path-id: path-id })
)

(define-read-only (get-learner-progress (progress-id uint))
  (map-get? learner-progress { progress-id: progress-id })
)

(define-read-only (get-skill-achievement (achievement-id uint))
  (map-get? skill-achievements { achievement-id: achievement-id })
)

(define-read-only (get-community-badge (badge-id uint))
  (map-get? community-badges { badge-id: badge-id })
)

(define-read-only (get-learner-badge (learner principal) (badge-id uint))
  (map-get? learner-badges { learner: learner, badge-id: badge-id })
)

(define-read-only (get-skill-assessment (assessment-id uint))
  (map-get? skill-assessments { assessment-id: assessment-id })
)

(define-read-only (get-learning-resource (resource-id uint))
  (map-get? learning-resources { resource-id: resource-id })
)

(define-read-only (get-learning-stats)
  {
    total-paths: (var-get total-paths),
    total-learners: (var-get total-learners),
    total-achievements: (var-get total-achievements),
    total-badges-earned: (var-get total-badges-earned),
    next-path-id: (var-get next-path-id),
    next-progress-id: (var-get next-progress-id),
    next-achievement-id: (var-get next-achievement-id),
    next-badge-id: (var-get next-badge-id),
    next-assessment-id: (var-get next-assessment-id),
    next-resource-id: (var-get next-resource-id)
  }
)

