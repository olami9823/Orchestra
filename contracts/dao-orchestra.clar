(define-constant err-unauthorized (err u101))
(define-constant err-not-found (err u102))

(define-data-var composition-counter uint u0)
(define-data-var concert-counter uint u0)
(define-data-var ticket-counter uint u0)

(define-map compositions {id: uint} {title: (string-ascii 100), creators: (list 10 principal), royalty-split: (list 10 uint), status: (string-ascii 20)})
(define-map concerts {id: uint} {title: (string-ascii 100), program: (list 10 uint), guest-performer: (optional principal), ticket-price: uint, date: uint})
(define-map tickets {id: uint} {concert-id: uint, owner: principal, price-paid: uint})


(define-public (create-composition (title (string-ascii 100)) (creators (list 10 principal)) (royalty-split (list 10 uint)))
  (let ((composition-id (+ (var-get composition-counter) u1)))
    (asserts! (is-eq (len creators) (len royalty-split)) err-unauthorized)
    (asserts! (is-eq (fold + royalty-split u0) u100) err-unauthorized)
    (asserts! (> (len title) u0) err-unauthorized)
    (map-set compositions
      { id: composition-id }
      { title: title, creators: creators, royalty-split: royalty-split, status: "active" })
    (var-set composition-counter composition-id)
    (ok composition-id)))

(define-public (create-concert (title (string-ascii 100)) (program (list 10 uint)) (ticket-price uint) (date uint))
  (let ((concert-id (+ (var-get concert-counter) u1)))
    (asserts! (> (len title) u0) err-unauthorized)
    (asserts! (> (len program) u0) err-unauthorized)
    (asserts! (> ticket-price u0) err-unauthorized)
    (asserts! (> date block-height) err-unauthorized)
    (map-set concerts
      { id: concert-id }
      { title: title, program: program, guest-performer: none, ticket-price: ticket-price, date: date })
    (var-set concert-counter concert-id)
    (ok concert-id)))

(define-public (buy-ticket (concert-id uint))
  (let ((concert (unwrap! (map-get? concerts { id: concert-id }) err-not-found))
        (ticket-id (+ (var-get ticket-counter) u1)))
    (asserts! (< block-height (get date concert)) err-unauthorized)
    (try! (stx-transfer? (get ticket-price concert) tx-sender (as-contract tx-sender)))
    (map-set tickets
      { id: ticket-id }
      { concert-id: concert-id, owner: tx-sender, price-paid: (get ticket-price concert) })
    (var-set ticket-counter ticket-id)
    (ok ticket-id)))

