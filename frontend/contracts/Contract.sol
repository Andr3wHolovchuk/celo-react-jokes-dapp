// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/** @title Contract to use signatures */
contract Verifier {
    address private owner;

    // set owner as contract's deployer
    constructor() {
        owner = msg.sender;
    }

    function verify_signer(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal view returns (bool) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        address signer = ECDSA.recover(_ethSignedMessageHash, v, r, s);

        if (signer == owner) {
            return true;
        }

        return false;
    }

    function splitSignature(
        bytes memory sig
    ) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature
            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature
            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

/** @title Contract for the publication of a jokes */
contract JokesContract is Verifier{
    // contract's owner address
    address owner;

    // set owner as contract's deployer
    constructor() {
        owner = msg.sender;
    }

    uint internal joke_counter = 0;
    uint internal category_counter = 0;

    struct Joke {
        string title;
        string content;
        uint category_id;
        address user;
        uint create_timestamp;
    }

    address[] public users;

    mapping(uint => Joke) jokes;

    string[] categories;

    /** @dev checks if a contract caller is an owner of the contract */
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not an owner");
        _;
    }

    /** @dev adds user to all users list
     * @param user address of a joke owner
     */
    function addUser(address user) public {
        bool new_user = true;

        for (uint i = 0; i < users.length; i++) {
            if (users[i] == user) {
                new_user = false;
            }
        }

        // if user is a new user on the site, save his address
        if (new_user == true) {
            users.push(user);
        }
    }

    function donate(
        address destination, 
        bytes32 hash, 
        bytes memory signature
    ) public payable {
        require(verify_signer(hash, signature), "You are not allowed");
        payable(destination).transfer(msg.value);
    }

    /** @dev checks if user is an owner
     * @return bool
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @return all users addresses
     */
    function allUsers() public view returns (address[] memory) {
        return users;
    }

    /** @dev adds a new joke to a list
     * @param joke_element object of a Joke struct
     */
    function addJoke(
        Joke calldata joke_element,
        bytes32 hash,
        bytes memory signature
    ) public {
        require(
            msg.sender == joke_element.user && verify_signer(hash, signature),
            "You are not allowed"
        );
        require(joke_counter + 1 <= type(uint256).max, "Counter overflow");
        require(
            joke_element.category_id < categories.length,
            "Invalid category id"
        );

        addUser(joke_element.user);

        jokes[joke_counter] = joke_element;

        joke_counter++;
    }

    /** @dev update an existing site
     * @param index index of a joke inside a contract
     * @param joke_element object of a Joke struct
     */
    function updateJoke(uint index, Joke calldata joke_element) public {
        require(index < joke_counter, "Joke index not found");

        require(msg.sender == jokes[index].user, "You are not allowed");

        jokes[index] = joke_element;
    }

    /** @dev adds a new category for jokes, only owners can do this
     * @param title title of a category
     */
    function addCategory(string memory title) public onlyOwner {
        categories.push(title);
    }

    /** @dev adds a new category for jokes, only owners can do this
     * @param index index of a category
     */
    function getCategory(uint index) public view returns (string memory) {
        return categories[index];
    }

    /**
     * @return all categories
     */
    function allCategories() public view returns (string[] memory) {
        return categories;
    }

    /** @dev returns all jokes
     * @return Joke[] array of Joke structs
     */
    function allJokes() public view returns (Joke[] memory) {
        Joke[] memory f = new Joke[](joke_counter);

        for (uint256 i = 0; i < joke_counter; i++) {
            f[i] = jokes[i];
        }

        return f;
    }

    /** @dev removes a specific joke by it's index
     * @param index index of a joke
     */
    function removeJoke(uint index) public {
        require(msg.sender == jokes[index].user, "You are not allowed");

        uint last_index = joke_counter - 1;
        jokes[index] = jokes[last_index];
        delete jokes[last_index];

        joke_counter--;
    }
}

/** @title NFT contract to deal with NFT tickets */
contract JokeNFT is ERC721, ERC721URIStorage, Ownable {
    // nft's counter
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("JOKRNF", "JKRN") {}

    string[] nft_urls = [
        "https://gateway.pinata.cloud/ipfs/QmdhzFXAGzub2q287HKPcz2qq6HqgT5cxVRhcNvNETDhQd",
        "https://gateway.pinata.cloud/ipfs/Qmdv1aUnP5Pw8UhNiuidzCk6S1Vt6nTxihx9r16YmYSuws",
        "https://gateway.pinata.cloud/ipfs/Qmadf2W8twBZ23WpcnnhCE7qo2heHwss6HLpARer9TPosN"
    ];

    function safeMint(
        address to,
        uint8 index,
        bytes32 hash,
        bytes memory signature
    ) public {
        // only client can mint his ticket NFT
        require(
            to == msg.sender && verify_signer(hash, signature),
            "You can't mint this NFT"
        );

        uint256 newItemId = _tokenIds.current();

        _mint(to, newItemId);

        _tokenIds.increment();

        // use custom uri from frontend
        _setTokenURI(newItemId, nft_urls[index]);
    }

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
