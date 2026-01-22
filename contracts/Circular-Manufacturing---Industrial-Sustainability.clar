(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_INVALID_STATUS (err u105))

(define-fungible-token eco-token)

(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var next-product-id uint u1)
(define-data-var next-waste-id uint u1)
(define-data-var recycling-reward-rate uint u100)

(define-map products
  { product-id: uint }
  {
    manufacturer: principal,
    name: (string-ascii 64),
    material-type: (string-ascii 32),
    weight: uint,
    created-at: uint,
    status: (string-ascii 16),
    lifecycle-stage: (string-ascii 16)
  }
)

(define-map product-history
  { product-id: uint, event-id: uint }
  {
    event-type: (string-ascii 32),
    timestamp: uint,
    actor: principal,
    location: (string-ascii 64),
    data: (string-ascii 128)
  }
)

(define-map waste-records
  { waste-id: uint }
  {
    product-id: uint,
    generator: principal,
    waste-type: (string-ascii 32),
    quantity: uint,
    location: (string-ascii 64),
    created-at: uint,
    status: (string-ascii 16)
  }
)

(define-map recycling-events
  { recycling-id: uint }
  {
    waste-id: uint,
    recycler: principal,
    method: (string-ascii 32),
    efficiency: uint,
    verified: bool,
    reward-amount: uint,
    timestamp: uint
  }
)

(define-map manufacturer-quotas
  { manufacturer: principal }
  {
    total-products: uint,
    recycling-quota: uint,
    current-recycled: uint,
    quota-period: uint
  }
)

(define-map iot-sensors
  { sensor-id: (string-ascii 32) }
  {
    owner: principal,
    location: (string-ascii 64),
    sensor-type: (string-ascii 32),
    active: bool
  }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-map carbon-footprints
  { product-id: uint }
  {
    total-emissions: uint,
    last-updated: uint,
    units: (string-ascii 16)
  }
)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-read-only (get-product (product-id uint))
  (map-get? products { product-id: product-id })
)

(define-read-only (get-waste-record (waste-id uint))
  (map-get? waste-records { waste-id: waste-id })
)

(define-read-only (get-recycling-event (recycling-id uint))
  (map-get? recycling-events { recycling-id: recycling-id })
)

(define-read-only (get-manufacturer-quota (manufacturer principal))
  (map-get? manufacturer-quotas { manufacturer: manufacturer })
)

(define-read-only (get-user-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-read-only (get-recycling-reward-rate)
  (var-get recycling-reward-rate)
)

(define-read-only (get-carbon-footprint (product-id uint))
  (map-get? carbon-footprints { product-id: product-id })
)

(define-public (register-product (name (string-ascii 64)) (material-type (string-ascii 32)) (weight uint))
  (let
    (
      (product-id (var-get next-product-id))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (begin
      (map-set products
        { product-id: product-id }
        {
          manufacturer: tx-sender,
          name: name,
          material-type: material-type,
          weight: weight,
          created-at: current-time,
          status: "active",
          lifecycle-stage: "production"
        }
      )
      (var-set next-product-id (+ product-id u1))
      (unwrap-panic (update-manufacturer-quota tx-sender u1))
      (ok product-id)
    )
  )
)

(define-public (update-product-lifecycle (product-id uint) (new-stage (string-ascii 16)) (location (string-ascii 64)))
  (let
    (
      (product-data (unwrap! (map-get? products { product-id: product-id }) ERR_NOT_FOUND))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (asserts! (is-eq tx-sender (get manufacturer product-data)) ERR_UNAUTHORIZED)
    (map-set products
      { product-id: product-id }
      (merge product-data { lifecycle-stage: new-stage })
    )
    (unwrap-panic (add-product-event product-id "lifecycle-update" location new-stage))
    (ok true)
  )
)

(define-public (register-waste (product-id uint) (waste-type (string-ascii 32)) (quantity uint) (location (string-ascii 64)))
  (let
    (
      (waste-id (var-get next-waste-id))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (asserts! (is-some (map-get? products { product-id: product-id })) ERR_NOT_FOUND)
    (map-set waste-records
      { waste-id: waste-id }
      {
        product-id: product-id,
        generator: tx-sender,
        waste-type: waste-type,
        quantity: quantity,
        location: location,
        created-at: current-time,
        status: "pending"
      }
    )
    (var-set next-waste-id (+ waste-id u1))
    (ok waste-id)
  )
)

(define-public (verify-recycling (waste-id uint) (method (string-ascii 32)) (efficiency uint))
  (let
    (
      (waste-data (unwrap! (map-get? waste-records { waste-id: waste-id }) ERR_NOT_FOUND))
      (reward-amount (* (get quantity waste-data) (var-get recycling-reward-rate) efficiency))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (recycling-id waste-id)
    )
    (asserts! (is-eq (get status waste-data) "pending") ERR_INVALID_STATUS)
    (map-set waste-records
      { waste-id: waste-id }
      (merge waste-data { status: "recycled" })
    )
    (map-set recycling-events
      { recycling-id: recycling-id }
      {
        waste-id: waste-id,
        recycler: tx-sender,
        method: method,
        efficiency: efficiency,
        verified: true,
        reward-amount: (/ reward-amount u100),
        timestamp: current-time
      }
    )
    (try! (mint-tokens tx-sender (/ reward-amount u100)))
    (unwrap-panic (update-recycling-quota (get generator waste-data)))
    (ok recycling-id)
  )
)

(define-public (register-iot-sensor (sensor-id (string-ascii 32)) (location (string-ascii 64)) (sensor-type (string-ascii 32)))
  (begin
    (asserts! (is-none (map-get? iot-sensors { sensor-id: sensor-id })) ERR_ALREADY_EXISTS)
    (map-set iot-sensors
      { sensor-id: sensor-id }
      {
        owner: tx-sender,
        location: location,
        sensor-type: sensor-type,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (submit-sensor-data (sensor-id (string-ascii 32)) (product-id uint) (data (string-ascii 128)))
  (let
    (
      (sensor-data (unwrap! (map-get? iot-sensors { sensor-id: sensor-id }) ERR_NOT_FOUND))
      (product-data (unwrap! (map-get? products { product-id: product-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get owner sensor-data)) ERR_UNAUTHORIZED)
    (asserts! (get active sensor-data) ERR_INVALID_STATUS)
    (unwrap-panic (add-product-event product-id "sensor-data" (get location sensor-data) data))
    (ok true)
  )
)

(define-public (mint-tokens (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (try! (ft-mint? eco-token amount recipient))
    (unwrap-panic (update-user-balance recipient amount))
    (ok true)
  )
)

(define-public (transfer-tokens (recipient principal) (amount uint))
  (let
    (
      (sender-balance (get-user-balance tx-sender))
    )
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    (try! (ft-transfer? eco-token amount tx-sender recipient))
    (unwrap-panic (decrease-user-balance tx-sender amount))
    (unwrap-panic (update-user-balance recipient amount))
    (ok true)
  )
)

(define-public (set-recycling-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (var-set recycling-reward-rate new-rate)
    (ok true)
  )
)

(define-public (update-carbon-footprint (product-id uint) (emissions uint) (units (string-ascii 16)))
  (let
    (
      (product-data (unwrap! (map-get? products { product-id: product-id }) ERR_NOT_FOUND))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (existing-footprint (default-to
        { total-emissions: u0, last-updated: u0, units: "" }
        (map-get? carbon-footprints { product-id: product-id })
      ))
    )
    (asserts! (is-eq tx-sender (get manufacturer product-data)) ERR_UNAUTHORIZED)
    (map-set carbon-footprints
      { product-id: product-id }
      {
        total-emissions: (+ (get total-emissions existing-footprint) emissions),
        last-updated: current-time,
        units: units
      }
    )
    (ok true)
  )
)

(define-public (register-product-with-carbon (name (string-ascii 64)) (material-type (string-ascii 32)) (weight uint) (initial-carbon uint) (units (string-ascii 16)))
  (let
    (
      (product-id (var-get next-product-id))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (begin
      (map-set products
        { product-id: product-id }
        {
          manufacturer: tx-sender,
          name: name,
          material-type: material-type,
          weight: weight,
          created-at: current-time,
          status: "active",
          lifecycle-stage: "production"
        }
      )
      (map-set carbon-footprints
        { product-id: product-id }
        {
          total-emissions: initial-carbon,
          last-updated: current-time,
          units: units
        }
      )
      (var-set next-product-id (+ product-id u1))
      (unwrap-panic (update-manufacturer-quota tx-sender u1))
      (ok product-id)
    )
  )
)

(define-private (add-product-event (product-id uint) (event-type (string-ascii 32)) (location (string-ascii 64)) (data (string-ascii 128)))
  (let
    (
      (event-id (+ (* product-id u1000) (len data)))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (begin
      (map-set product-history
        { product-id: product-id, event-id: event-id }
        {
          event-type: event-type,
          timestamp: current-time,
          actor: tx-sender,
          location: location,
          data: data
        }
      )
      (ok true)
    )
  )
)

(define-private (update-manufacturer-quota (manufacturer principal) (products-added uint))
  (let
    (
      (current-quota (default-to
        { total-products: u0, recycling-quota: u0, current-recycled: u0, quota-period: u365 }
        (map-get? manufacturer-quotas { manufacturer: manufacturer })
      ))
    )
    (begin
      (map-set manufacturer-quotas
        { manufacturer: manufacturer }
        (merge current-quota {
          total-products: (+ (get total-products current-quota) products-added),
          recycling-quota: (+ (get recycling-quota current-quota) (* products-added u70))
        })
      )
      (ok true)
    )
  )
)

(define-private (update-recycling-quota (manufacturer principal))
  (let
    (
      (current-quota (unwrap! (map-get? manufacturer-quotas { manufacturer: manufacturer }) ERR_NOT_FOUND))
    )
    (begin
      (map-set manufacturer-quotas
        { manufacturer: manufacturer }
        (merge current-quota {
          current-recycled: (+ (get current-recycled current-quota) u1)
        })
      )
      (ok true)
    )
  )
)

(define-private (update-user-balance (user principal) (amount uint))
  (let
    (
      (current-balance (get-user-balance user))
    )
    (begin
      (map-set user-balances
        { user: user }
        { balance: (+ current-balance amount) }
      )
      (ok true)
    )
  )
)

(define-private (decrease-user-balance (user principal) (amount uint))
  (let
    (
      (current-balance (get-user-balance user))
    )
    (begin
      (asserts! (>= current-balance amount) ERR_INSUFFICIENT_BALANCE)
      (map-set user-balances
        { user: user }
        { balance: (- current-balance amount) }
      )
      (ok true)
    )
  )
)

(define-data-var next-batch-id uint u1)

(define-map product-batches
  { batch-id: uint }
  {
    manufacturer: principal,
    product-ids: (list 100 uint),
    batch-size: uint,
    created-at: uint,
    status: (string-ascii 16)
  }
)

(define-read-only (get-product-batch (batch-id uint))
  (map-get? product-batches { batch-id: batch-id })
)

(define-public (create-product-batch (product-ids (list 100 uint)) (batch-size uint))
  (let
    (
      (batch-id (var-get next-batch-id))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (begin
      (asserts! (> batch-size u0) ERR_INVALID_AMOUNT)
      (asserts! (is-eq (len product-ids) batch-size) ERR_INVALID_AMOUNT)
      (map-set product-batches
        { batch-id: batch-id }
        {
          manufacturer: tx-sender,
          product-ids: product-ids,
          batch-size: batch-size,
          created-at: current-time,
          status: "active"
        }
      )
      (var-set next-batch-id (+ batch-id u1))
      (ok batch-id)
    )
  )
)

(define-public (update-batch-status (batch-id uint) (new-status (string-ascii 16)))
  (let
    (
      (batch-data (unwrap! (map-get? product-batches { batch-id: batch-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get manufacturer batch-data)) ERR_UNAUTHORIZED)
    (map-set product-batches
      { batch-id: batch-id }
      (merge batch-data { status: new-status })
    )
    (ok true)
  )
)

(define-map circularity-scores
  { product-id: uint }
  {
    score: uint,
    last-calculated: uint,
    factors: { recycling-rate: uint, carbon-efficiency: uint, lifecycle-completeness: uint }
  }
)

(define-read-only (get-circularity-score (product-id uint))
  (map-get? circularity-scores { product-id: product-id })
)

(define-public (calculate-circularity-score (product-id uint))
  (let
    (
      (product-data (unwrap! (map-get? products { product-id: product-id }) ERR_NOT_FOUND))
      (carbon-data (default-to { total-emissions: u0, last-updated: u0, units: "" } (map-get? carbon-footprints { product-id: product-id })))
      (recycling-events-count (var-get next-waste-id))
      (lifecycle-stage (get lifecycle-stage product-data))
      (recycling-rate (if (> recycling-events-count u0) (/ (* u100 (len (filter-recycling-events product-id))) recycling-events-count) u0))
      (carbon-efficiency (if (> (get total-emissions carbon-data) u0) (/ u100000 (get total-emissions carbon-data)) u100))
      (lifecycle-completeness (if (is-eq lifecycle-stage "disposed") u100 (if (is-eq lifecycle-stage "recycled") u80 u50)))
      (total-score (/ (+ recycling-rate carbon-efficiency lifecycle-completeness) u3))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (map-set circularity-scores
      { product-id: product-id }
      {
        score: total-score,
        last-calculated: current-time,
        factors: { recycling-rate: recycling-rate, carbon-efficiency: carbon-efficiency, lifecycle-completeness: lifecycle-completeness }
      }
    )
    (ok total-score)
  )
)

(define-public (transfer-product-ownership (product-id uint) (new-owner principal))
 (let
   (
     (product-data (unwrap! (map-get? products { product-id: product-id }) ERR_NOT_FOUND))
   )
   (asserts! (is-eq tx-sender (get manufacturer product-data)) ERR_UNAUTHORIZED)
   (map-set products
     { product-id: product-id }
     (merge product-data { manufacturer: new-owner })
   )
   (unwrap-panic (add-product-event product-id "ownership-transfer" "" "transferred"))
   (ok true)
 )
)

(define-private (filter-recycling-events (product-id uint))
  (list u0)
)
