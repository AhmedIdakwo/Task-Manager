;; Decentralized Work Collaboration Smart Contract

;; Constants
(define-constant contract-admin tx-sender)
(define-constant error-access-denied (err u100))
(define-constant error-contract-already-active (err u101))
(define-constant error-item-not-found (err u102))
(define-constant error-invalid-task-state (err u103))
(define-constant error-insufficient-funds (err u104))
(define-constant error-invalid-priority (err u105))
(define-constant error-invalid-input (err u106))

;; Data maps
(define-map member-profiles principal { member-role: (string-ascii 20), member-status: (string-ascii 10) })
(define-map project-tasks uint { task-title: (string-ascii 50), task-details: (string-utf8 500), task-progress: (string-ascii 10), task-owner: principal, task-deadline: uint })
(define-map member-earnings principal uint)
(define-map task-comments uint { task-id: uint, commenter: principal, comment-text: (string-utf8 500), timestamp: uint })
(define-map task-priorities uint (string-ascii 10))
(define-map member-reputation principal uint)
(define-map task-dependencies uint (list 10 uint))
(define-map task-time-logs uint { task-id: uint, member: principal, time-spent: uint, timestamp: uint })

;; Data variables
(define-data-var task-counter uint u0)
(define-data-var contract-state (string-ascii 10) "inactive")
(define-data-var comment-counter uint u0)
(define-data-var time-log-counter uint u0)

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

(define-read-only (get-task-comment (comment-id uint))
  (map-get? task-comments comment-id)
)

(define-read-only (get-task-priority (task-id uint))
  (default-to "medium" (map-get? task-priorities task-id))
)

(define-read-only (get-member-reputation (member principal))
  (default-to u0 (map-get? member-reputation member))
)

(define-read-only (get-task-dependencies (task-id uint))
  (default-to (list) (map-get? task-dependencies task-id))
)

(define-read-only (get-task-time-log (log-id uint))
  (map-get? task-time-logs log-id)
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
    (asserts! (> (len task-title) u0) error-invalid-input)
    (asserts! (> (len task-details) u0) error-invalid-input)
    (asserts! (> task-deadline block-height) error-invalid-input)
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
    (asserts! (> fund-amount u0) error-invalid-input)
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

;; New functions for added features

(define-public (add-task-comment (task-id uint) (comment-text (string-utf8 500)))
  (let ((new-comment-id (+ (var-get comment-counter) u1)))
    (asserts! (is-active-member tx-sender) error-access-denied)
    (asserts! (is-some (get-task-details task-id)) error-item-not-found)
    (asserts! (> (len comment-text) u0) error-invalid-input)
    (map-set task-comments new-comment-id 
             { task-id: task-id, commenter: tx-sender, comment-text: comment-text, timestamp: block-height })
    (var-set comment-counter new-comment-id)
    (ok new-comment-id)
  )
)

(define-public (set-task-priority (task-id uint) (priority (string-ascii 10)))
  (let ((task (unwrap! (get-task-details task-id) error-item-not-found)))
    (asserts! (is-active-member tx-sender) error-access-denied)
    (asserts! (or (is-eq tx-sender (get task-owner task)) (is-contract-admin)) error-access-denied)
    (asserts! (or (is-eq priority "low") (is-eq priority "medium") (is-eq priority "high")) error-invalid-priority)
    (map-set task-priorities task-id priority)
    (ok true)
  )
)

(define-public (update-member-reputation (member principal) (reputation-change int))
  (begin
    (asserts! (is-contract-admin) error-access-denied)
    (asserts! (is-some (get-member-profile member)) error-item-not-found)
    (let (
      (current-reputation (default-to u0 (map-get? member-reputation member)))
      (new-reputation (if (> reputation-change 0)
        (+ current-reputation (to-uint reputation-change))
        (if (>= (to-int current-reputation) (* reputation-change -1))
          (to-uint (+ (to-int current-reputation) reputation-change))
          u0
        )))
    )
      (map-set member-reputation member new-reputation)
      (ok true)
    )
  )
)

(define-public (set-task-dependencies (task-id uint) (dependency-ids (list 10 uint)))
  (begin
    (asserts! (is-active-member tx-sender) error-access-denied)
    (asserts! (is-some (get-task-details task-id)) error-item-not-found)
    (asserts! (> (len dependency-ids) u0) error-invalid-input)
    (map-set task-dependencies task-id dependency-ids)
    (ok true)
  )
)

(define-public (log-task-time (task-id uint) (time-spent uint))
  (let ((new-log-id (+ (var-get time-log-counter) u1)))
    (asserts! (is-active-member tx-sender) error-access-denied)
    (asserts! (is-some (get-task-details task-id)) error-item-not-found)
    (asserts! (> time-spent u0) error-invalid-input)
    (map-set task-time-logs new-log-id 
             { task-id: task-id, member: tx-sender, time-spent: time-spent, timestamp: block-height })
    (var-set time-log-counter new-log-id)
    (ok new-log-id)
  )
)

;; Contract initialization
(activate-contract)