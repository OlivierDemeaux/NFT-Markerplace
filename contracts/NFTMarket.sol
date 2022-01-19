//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Market {

    using Counters for Counters.Counter;

    //Id of the next listing
    Counters.Counter private _listingCounter;

    enum ListingStatus {
        Active,
        Sold,
        Canceled
    }

    struct Listing {
        ListingStatus status;
        address seller;
        address token;
        uint tokenId;
        uint price;
    }

    event Listed(
        uint listingId,
        address seller,
        address token,
        uint tokenId,
        uint price
    );

    event Sale(
        uint listingId,
        address buyer,
        address token,
        uint tokenId,
        uint price
    );

    event Cancel(
        uint listingId,
        address seller
    );

    mapping (uint => Listing) private _listings;
   
   function listToken(address token, uint tokenId, uint price) public {
       IERC721(token).transferFrom(msg.sender, address(this), tokenId);
       _listings[_listingCounter.current()] = Listing(ListingStatus.Active, msg.sender, token,tokenId,price);
       emit Listed(_listingCounter.current(), msg.sender, token, tokenId, price);
       _listingCounter.increment();
   }

   function getListing(uint listingId) public view returns(Listing memory) {
       return(_listings[listingId]);
   }

   function buyToken(uint listingId) public payable {
       Listing storage listing = _listings[listingId];
       require(listing.status == ListingStatus.Active, "This listing is not active");
       require(msg.sender != listing.seller, "Seller can not be buyer");
       require(msg.value >= listing.price, "Insufficient payment");

       IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenId);
       payable(listing.seller).transfer(listing.price);
       emit Sale(listingId, msg.sender, listing.token, listing.tokenId, listing.price);
   }

   function cancelListing(uint listingId) public {
       Listing storage listing = _listings[listingId];
       require(msg.sender == listing.seller, "only seller can cancel listing");
       require(listing.status == ListingStatus.Active, "Listing is not active");

       listing.status = ListingStatus.Canceled;
       emit Cancel(listingId, msg.sender);
   }
}
