(define-constant ERR_NOT_AUTHORIZED u100)
(define-constant ERR_AUCTION_NOT_FOUND u101)
(define-constant ERR_AUCTION_ENDED u102)
(define-constant ERR_AUCTION_ACTIVE u103)
(define-constant ERR_BID_TOO_LOW u104)
(define-constant ERR_INVALID_DURATION u105)
(define-constant ERR_INVALID_STARTING_BID u106)
(define-constant ERR_SELF_BID u107)
(define-constant ERR_NO_BIDS u108)
(define-constant ERR_ALREADY_FINALIZED u109)
(define-constant ERR_NOT_ENDED u110)
(define-constant ERR_RESERVE_NOT_MET u111)

(define-data-var auction-counter uint u0)

(define-map auctions
  { auction-id: uint }
  {
    seller: principal,
    item-name: (string-ascii 64),
    description: (string-ascii 256),
    starting-bid: uint,
    reserve-price: uint,
    current-bid: uint,
    highest-bidder: (optional principal),
    end-block: uint,
    finalized: bool
  })

(define-map bids
  { auction-id: uint, bidder: principal }
  { amount: uint, stacks-block-height: uint })

(define-map user-bids
  { user: principal, auction-id: uint }
  { amount: uint })

(define-private (get-next-auction-id)
  (let ((current-id (var-get auction-counter)))
    (var-set auction-counter (+ current-id u1))
    (+ current-id u1)))

(define-public (create-auction (item-name (string-ascii 64)) 
                              (description (string-ascii 256))
                              (starting-bid uint)
                              (reserve-price uint)
                              (duration uint))
  (let ((auction-id (get-next-auction-id))
        (end-block (+ stacks-block-height duration)))
    (asserts! (> duration u0) (err ERR_INVALID_DURATION))
    (asserts! (> starting-bid u0) (err ERR_INVALID_STARTING_BID))
    (asserts! (>= reserve-price starting-bid) (err ERR_INVALID_STARTING_BID))
    (map-set auctions
      { auction-id: auction-id }
      {
        seller: tx-sender,
        item-name: item-name,
        description: description,
        starting-bid: starting-bid,
        reserve-price: reserve-price,
        current-bid: starting-bid,
        highest-bidder: none,
        end-block: end-block,
        finalized: false
      })
    (ok auction-id)))

(define-public (place-bid (auction-id uint) (bid-amount uint))
  (let ((auction-data (unwrap! (map-get? auctions { auction-id: auction-id }) 
                               (err ERR_AUCTION_NOT_FOUND))))
    (asserts! (<= stacks-block-height (get end-block auction-data)) 
              (err ERR_AUCTION_ENDED))
    (asserts! (not (is-eq tx-sender (get seller auction-data))) 
              (err ERR_SELF_BID))
    (asserts! (> bid-amount (get current-bid auction-data)) 
              (err ERR_BID_TOO_LOW))
    (asserts! (not (get finalized auction-data)) 
              (err ERR_ALREADY_FINALIZED))
    
    (let ((previous-bidder (get highest-bidder auction-data))
          (previous-bid (get current-bid auction-data)))
      
      (try! (stx-transfer? bid-amount tx-sender (as-contract tx-sender)))
      
      (match previous-bidder
        bidder (try! (as-contract (stx-transfer? previous-bid 
                                               tx-sender bidder)))
        true)
      
      (map-set auctions
        { auction-id: auction-id }
        (merge auction-data {
          current-bid: bid-amount,
          highest-bidder: (some tx-sender)
        }))
      
      (map-set bids
        { auction-id: auction-id, bidder: tx-sender }
        { amount: bid-amount, stacks-block-height: stacks-block-height })
      
      (map-set user-bids
        { user: tx-sender, auction-id: auction-id }
        { amount: bid-amount })
      
      (ok true))))

(define-public (finalize-auction (auction-id uint))
  (let ((auction-data (unwrap! (map-get? auctions { auction-id: auction-id }) 
                               (err ERR_AUCTION_NOT_FOUND))))
    (asserts! (> stacks-block-height (get end-block auction-data)) 
              (err ERR_NOT_ENDED))
    (asserts! (not (get finalized auction-data)) 
              (err ERR_ALREADY_FINALIZED))
    
    (match (get highest-bidder auction-data)
      winner (if (>= (get current-bid auction-data) (get reserve-price auction-data))
        (begin
          (try! (as-contract (stx-transfer? (get current-bid auction-data) 
                                          tx-sender (get seller auction-data))))
          (map-set auctions
            { auction-id: auction-id }
            (merge auction-data { finalized: true }))
          (ok winner))
        (begin
          (try! (as-contract (stx-transfer? (get current-bid auction-data) 
                                          tx-sender winner)))
          (map-set auctions
            { auction-id: auction-id }
            (merge auction-data { finalized: true }))
          (err ERR_RESERVE_NOT_MET)))
      (err ERR_NO_BIDS))))

(define-public (emergency-end-auction (auction-id uint))
  (let ((auction-data (unwrap! (map-get? auctions { auction-id: auction-id }) 
                               (err ERR_AUCTION_NOT_FOUND))))
    (asserts! (is-eq tx-sender (get seller auction-data)) 
              (err ERR_NOT_AUTHORIZED))
    (asserts! (<= stacks-block-height (get end-block auction-data)) 
              (err ERR_AUCTION_ENDED))
    (asserts! (not (get finalized auction-data)) 
              (err ERR_ALREADY_FINALIZED))
    
    (match (get highest-bidder auction-data)
      bidder (try! (as-contract (stx-transfer? (get current-bid auction-data) 
                                             tx-sender bidder)))
      true)
    
    (map-set auctions
      { auction-id: auction-id }
      (merge auction-data { 
        end-block: stacks-block-height,
        finalized: true 
      }))
    (ok true)))

(define-read-only (get-auction-details (auction-id uint))
  (map-get? auctions { auction-id: auction-id }))

(define-read-only (get-auction-status (auction-id uint))
  (let ((auction-data (unwrap! (map-get? auctions { auction-id: auction-id }) 
                               (err ERR_AUCTION_NOT_FOUND))))
    (ok {
      active: (and (<= stacks-block-height (get end-block auction-data))
                   (not (get finalized auction-data))),
      ended: (> stacks-block-height (get end-block auction-data)),
      finalized: (get finalized auction-data),
      current-block: stacks-block-height,
      end-block: (get end-block auction-data)
    })))

(define-read-only (get-bid-details (auction-id uint) (bidder principal))
  (map-get? bids { auction-id: auction-id, bidder: bidder }))

(define-read-only (get-user-bid (user principal) (auction-id uint))
  (map-get? user-bids { user: user, auction-id: auction-id }))

(define-read-only (get-current-auction-count)
  (var-get auction-counter))

(define-read-only (is-auction-active (auction-id uint))
  (match (map-get? auctions { auction-id: auction-id })
    auction-data (and (<= stacks-block-height (get end-block auction-data))
                      (not (get finalized auction-data)))
    false))

(define-read-only (get-time-remaining (auction-id uint))
  (match (map-get? auctions { auction-id: auction-id })
    auction-data (if (<= stacks-block-height (get end-block auction-data))
                     (ok (- (get end-block auction-data) stacks-block-height))
                     (ok u0))
    (err ERR_AUCTION_NOT_FOUND)))

(define-read-only (get-winning-bid (auction-id uint))
  (match (map-get? auctions { auction-id: auction-id })
    auction-data (ok {
      amount: (get current-bid auction-data),
      bidder: (get highest-bidder auction-data)
    })
    (err ERR_AUCTION_NOT_FOUND)))

(define-read-only (reserve-price-met (auction-id uint))
  (match (map-get? auctions { auction-id: auction-id })
    auction-data (ok (>= (get current-bid auction-data) (get reserve-price auction-data)))
    (err ERR_AUCTION_NOT_FOUND)))
