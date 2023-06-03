// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


/** @title Contact for the publication of jokes */
contract JokesContract is Ownable {
    /**
    @dev Library for counting and managing counters
    */
    using Counters for Counters.Counter;


    /**
    @dev Counter to keep track of the number of jokes
    */
    Counters.Counter private joke_counter;

    /**
    @dev Counter to keep track of the number of categories
    */
    Counters.Counter private category_counter;
    
    /**
     * @dev Event emitted when a new user is added.
     * @param user The address of the user added.
     */
    event UserAdded(address indexed user);

    /**
     * @dev Event emitted when funds are donated.
     * @param sender The address of the sender.
     * @param destination The address of the destination.
     * @param amount The amount of funds donated.
     */
    event Donation(address indexed sender, address indexed destination, uint256 amount);

    /**
     * @dev Event emitted when a joke is added.
     * @param index The index of the added joke.
     * @param joke_element The added joke object.
     */
    event JokeAdded(uint256 indexed index, Joke joke_element);

    /**
     * @dev Event emitted when a joke is updated.
     * @param index The index of the updated joke.
     * @param joke_element The updated joke object.
     */
    event JokeUpdated(uint256 indexed index, Joke joke_element);

    /**
     * @dev Event emitted when a category is added.
     * @param title The title of the added category.
     */
    event CategoryAdded(string title);

    /**
     * @dev Event emitted when a joke is removed.
     * @param index The index of the removed joke.
     */
    event JokeRemoved(uint256 indexed index);


    /**
    @dev Struct representing a joke
    @param title The title of the joke
    @param content The content of the joke
    @param category_id The ID of the category to which the joke belongs
    @param user The address of the user who submitted the joke
    @param create_timestamp The timestamp when the joke was created
    */
    struct Joke {
        string title;
        string content;
        uint256 category_id;
        address user;
        uint256 create_timestamp;
    }

    /**  
    @dev Array containing addresses of all users
    */
    address[] public users;

    /**   
    @dev Mapping to store jokes with their respective IDs
    */
    mapping(uint256 => Joke) jokes;

    /**
    @dev Array containing titles of all categories
    */
    string[] categories;

    /**
    @dev Adds a user to the list of users
    @param user Address of the user to be added
    */
    function addUser(address user) public onlyOwner {
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
        emit UserAdded(user);
    }

    /**
    @dev Transfers the specified amount of funds to the given destination address
    @param destination The address to which the funds will be transferred
    */
    function donate(address payable destination) public payable onlyOwner {
        require(destination != address(0), "Invalid destination address");
        require(msg.value > 0, "Invalid donation amount");
        destination.transfer(msg.value);
        emit Donation(msg.sender, destination, msg.value);
    }

    /**
    @dev Returns an array of all user addresses
    @return An array of all user addresses
    */
    function allUsers() public view returns (address[] memory) {
        return users;
    }

    /**
    @dev Adds a new joke to the contract
    @param joke_element The joke object to be added
    */
    function addJoke(Joke calldata joke_element) public {
        require(joke_element.user != address(0), "Invalid user address");
        require(msg.sender == joke_element.user, "You are not allowed");
        require(joke_counter.current() + 1 > joke_counter.current(), "Counter overflow");
        require(joke_element.category_id < categories.length, "Invalid category id");

        addUser(joke_element.user);

        jokes[joke_counter.current()] = joke_element;

        joke_counter.increment();
        emit JokeAdded(joke_counter.current() - 1, joke_element);
    }

    /**
    @dev Updates an existing joke in the contract
    @param index The index of the joke to be updated
    @param joke_element The updated joke object
    */
    function updateJoke(uint256 index, Joke calldata joke_element) public {
        require(index < joke_counter.current(), "Joke index not found");
        require(joke_element.user != address(0), "Invalid user address");
        require(msg.sender == jokes[index].user, "You are not allowed");
        require(joke_element.category_id < categories.length, "Invalid category id");

        jokes[index] = joke_element;
        emit JokeUpdated(index, joke_element);
    }

    /**
    @dev Adds a new category for jokes
    @param title The title of the category
    */
    function addCategory(string memory title) public onlyOwner {
        require(bytes(title).length > 0, "Category title cannot be empty");
        categories.push(title);
        emit CategoryAdded(title);
    }

    /**
    @dev Returns the category title at the specified index
    @param index The index of the category
    @return The category title
    */
    function getCategory(uint256 index) public view returns (string memory) {
        require(index < categories.length, "Invalid category index");
        return categories[index];
    }

    /**
    @dev Returns an array of all categories
    @return An array of all categories
    */
    function allCategories() public view returns (string[] memory) {
        return categories;
    }

    /**
    @dev Returns an array of all jokes
    @return An array of all jokes
    */
    function allJokes() public view returns (Joke[] memory) {
        Joke[] memory f = new Joke[](joke_counter.current());

        for (uint256 i = 0; i < joke_counter.current(); i++) {
            f[i] = jokes[i];
        }

        return f;
    }

    /**
    @dev Removes a joke at the specified index
    @param index The index of the joke to be removed
    */
    function removeJoke(uint256 index) public onlyOwner  {
        require(index < joke_counter.current(), "Invalid joke index");
        require(msg.sender == jokes[index].user, "You are not allowed");
        uint256 last_index = joke_counter.current() - 1;
        jokes[index] = jokes[last_index];
        delete jokes[last_index];

        joke_counter.decrement();
        emit JokeRemoved(index);
    }
}

/** @title NFT contract to deal with NFT tickets */
contract JokeNFT is ERC721URIStorage, Ownable {


    /**
     * @dev Event emitted when a new NFT is minted.
     * @param to The address to which the NFT is assigned.
     * @param tokenId The ID of the minted NFT.
     * @param tokenURI The URI of the minted NFT.
    */
    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);

    /**
     * @dev Event emitted when an NFT is burned.
     * @param tokenId The ID of the burned NFT.
    */
    event NFTBurned(uint256 indexed tokenId);

    
    /**
    * @dev The contract's internal counter for generating unique token IDs.
    */
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;


    /**
    * @dev Constructor of the contract.
    * It initializes the ERC721 token with the specified name and symbol.
    */
    constructor() ERC721("JOKRNF", "JKRN") {}


    /**
    * @dev Array containing the URLs of the NFTs.
    * The URLs represent the IPFS links where the NFT content is stored.
    */
    string[] nft_urls = [
        "https://gateway.pinata.cloud/ipfs/QmdhzFXAGzub2q287HKPcz2qq6HqgT5cxVRhcNvNETDhQd",
        "https://gateway.pinata.cloud/ipfs/Qmdv1aUnP5Pw8UhNiuidzCk6S1Vt6nTxihx9r16YmYSuws",
        "https://gateway.pinata.cloud/ipfs/Qmadf2W8twBZ23WpcnnhCE7qo2heHwss6HLpARer9TPosN"
    ];


    /**
    * @dev Mint a new NFT and assign it to the specified address.
    * Only the client who owns the NFT can mint it.
    * @param to The address to which the NFT will be assigned.
    * @param index The index of the NFT URL in the `nft_urls` array.
    * @dev Reverts if the caller is not the same as the specified address (`to`).
    * Reverts if the index is out of range for the `nft_urls` array.
    * @notice Emits an `NFTMinted` event upon successful minting.
    */
    function safeMint(
        address to,
        uint8 index
        ) public {
        // only client can mint his ticket NFT
        require(to == address(this),"You can't mint this NFT");
        require(index < nft_urls.length, "Invalid index");

        uint256 newItemId = _tokenIds.current();

        _mint(to, newItemId);

        _tokenIds.increment();

        // use custom uri from frontend
        _setTokenURI(newItemId, nft_urls[index]);

        emit NFTMinted(to, newItemId, nft_urls[index]);
    }


    /**
    * @dev Burn the specified NFT.
    * @param tokenId The ID of the NFT to be burned.
    * @dev Reverts if the specified token does not exist.
    * @notice Emits an `NFTBurned` event upon successful burning.
    */
    function _burn(
        uint256 tokenId
    ) internal override(ERC721URIStorage) {
        require(_exists(tokenId), "Token does not exist");
        super._burn(tokenId);
        // Emit NFTBurned event
        emit NFTBurned(tokenId);
    }


    /**
    * @dev Get the URI associated with the specified NFT.
    * @param tokenId The ID of the NFT.
    * @return The URI string of the specified NFT.
    * @dev Reverts if the specified token does not exist.
    */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return super.tokenURI(tokenId);
        
    }
}
