// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


/** @title Contact for the publication of jokes */
contract JokesContract is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private joke_counter;
    Counters.Counter private category_counter;

    struct Joke {
        string title;
        string content;
        uint256 category_id;
        address user;
        uint256 create_timestamp;
    }

    address[] public users;
    mapping(uint256 => Joke) jokes;
    string[] categories;

    function addUser(address user) public {
        require(user != address(0), "Invalid user address");
        if (users.length == 0) {
            users.push(user);
        } else {
            bool new_user = true;

            for (uint256 i = 0; i < users.length; i++) {
                if (users[i] == user) {
                    new_user = false;
                }
            }

            if (new_user == true) {
                users.push(user);
            }
        }
    }

    function donate(address payable destination) public payable {
        destination.transfer(msg.value);
    }

    function allUsers() public view returns (address[] memory) {
        return users;
    }

    function addJoke(Joke calldata joke_element) public {
        require(msg.sender == joke_element.user, "You are not allowed");
        require(joke_counter.current() + 1 > joke_counter.current(), "Counter overflow");
        require(joke_element.category_id < categories.length, "Invalid category id");

        addUser(joke_element.user);

        jokes[joke_counter.current()] = joke_element;

        joke_counter.increment();
    }

    function updateJoke(uint256 index, Joke calldata joke_element) public {
        require(index < joke_counter.current(), "Joke index not found");
        require(msg.sender == jokes[index].user, "You are not allowed");

        jokes[index] = joke_element;
    }

    function addCategory(string memory title) public onlyOwner {
        categories.push(title);
    }

    function getCategory(uint256 index) public view returns (string memory) {
        return categories[index];
    }

    function allCategories() public view returns (string[] memory) {
        return categories;
    }

    function allJokes() public view returns (Joke[] memory) {
        Joke[] memory f = new Joke[](joke_counter.current());

        for (uint256 i = 0; i < joke_counter.current(); i++) {
            f[i] = jokes[i];
        }

        return f;
    }

    function removeJoke(uint256 index) public {
        require(msg.sender == jokes[index].user, "You are not allowed");

        uint256 last_index = joke_counter.current() - 1;
        jokes[index] = jokes[last_index];
        delete jokes[last_index];

        joke_counter.decrement();
    }
}

/** @title NFT contract to deal with NFT tickets */
contract JokeNFT is ERC721URIStorage, Ownable {
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
        uint8 index
    ) public {
        // only client can mint his ticket NFT
        require(
            to == msg.sender,
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
    ) internal override(ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
