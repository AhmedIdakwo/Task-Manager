;; Decentralized Work Collaboration Smart Contract

;; Constants
(define-constant contract-admin tx-sender)
(define-constant error-access-denied (err u100))
(define-constant error-contract-already-active (err u101))
(define-constant error-item-not-found (err u102))
(define-constant error-invalid-task-state (err u103))
(define-constant error-insufficient-funds (err u104))

;; Data maps
(define-map member-profiles principal { member-role: (string-ascii 20), member-status: (string-ascii 10) })
(define-map project-tasks uint { task-title: (string-ascii 50), task-details: (string-utf8 500), task-progress: (string-ascii 10), task-owner: principal, task-deadline: uint })
(define-map member-earnings principal uint)

;; Data variables
(define-data-var task-counter uint u0)
(define-data-var contract-state (string-ascii 10) "inactive")

;; Read-only functions
(define-read-only (get-member-profile (member-address principal))
  (map-get? member-profiles member-address)
)

(define-read-only (get-task-details (task-id uint))
  (map-get? project-tasks task-id)
)

(define-read-only (get-member-balance (member-address principal))
  (default-to u0 (map-get? member-earnings member-address))
)

(define-read-only (get-current-contract-state)
  (var-get contract-state)
)

;; Private functions
(define-private (is-contract-admin)
  (is-eq tx-sender contract-admin)
)

(define-private (is-active-member (member-address principal))
  (match (get-member-profile member-address)
    member-data (is-eq (get member-status member-data) "active")
    false
  )
)

(define-private (register-authorized-member (member-address principal))
  (begin
    (asserts! (is-contract-admin) error-access-denied)
    (map-set member-profiles member-address { member-role: "contributor", member-status: "active" })
    (ok true)
  )
)

;; Public functions
(define-public (activate-contract)
  (begin
    (asserts! (is-contract-admin) error-access-denied)
    (asserts! (is-eq (var-get contract-state) "inactive") error-contract-already-active)
    (var-set contract-state "active")
    (map-set member-profiles contract-admin { member-role: "admin", member-status: "active" })
    (ok true)
  )
)

(define-public (onboard-new-member (new-member-address principal))
  (begin
    (asserts! (is-active-member tx-sender) error-access-denied)
    (asserts! (is-none (get-member-profile new-member-address)) error-contract-already-active)
    (register-authorized-member new-member-address)
  )
)

(define-public (offboard-member (member-address principal))
  (begin
    (asserts! (or (is-contract-admin) (is-eq tx-sender member-address)) error-access-denied)
    (asserts! (is-some (get-member-profile member-address)) error-item-not-found)
    (map-delete member-profiles member-address)
    (ok true)
  )
)

(define-public (create-task (task-title (string-ascii 50)) (task-details (string-utf8 500)) (task-owner principal) (task-deadline uint))
  (let ((new-task-id (+ (var-get task-counter) u1)))
    (asserts! (is-active-member tx-sender) error-access-denied)
    (asserts! (is-active-member task-owner) error-access-denied)
    (map-set project-tasks new-task-id { task-title: task-title, task-details: task-details, task-progress: "pending", task-owner: task-owner, task-deadline: task-deadline })
    (var-set task-counter new-task-id)
    (ok new-task-id)
  )
)

(define-public (update-task-progress (task-id uint) (new-progress-state (string-ascii 10)))
  (let ((task (unwrap! (get-task-details task-id) error-item-not-found)))
    (asserts! (is-active-member tx-sender) error-access-denied)
    (asserts! (or (is-eq tx-sender (get task-owner task)) (is-contract-admin)) error-access-denied)
    (asserts! (or (is-eq new-progress-state "pending") (is-eq new-progress-state "in-progress") (is-eq new-progress-state "completed")) error-invalid-task-state)
    (map-set project-tasks task-id (merge task { task-progress: new-progress-state }))
    (ok true)
  )
)

(define-public (allocate-funds (recipient-member principal) (fund-amount uint))
  (begin
    (asserts! (is-contract-admin) error-access-denied)
    (asserts! (is-active-member recipient-member) error-access-denied)
    (map-set member-earnings recipient-member (+ (get-member-balance recipient-member) fund-amount))
    (ok true)
  )
)

(define-public (withdraw-funds (withdrawal-amount uint))
  (let ((current-funds (get-member-balance tx-sender)))
    (asserts! (is-active-member tx-sender) error-access-denied)
    (asserts! (<= withdrawal-amount current-funds) error-insufficient-funds)
    (map-set member-earnings tx-sender (- current-funds withdrawal-amount))
    (as-contract (stx-transfer? withdrawal-amount tx-sender tx-sender))
  )
)

(define-public (cast-vote (proposal-id uint) (member-decision bool))
  (begin
    (asserts! (is-active-member tx-sender) error-access-denied)
    ;; Implement voting logic here
    (ok true)
  )
)

;; Contract initialization
(activate-contract)