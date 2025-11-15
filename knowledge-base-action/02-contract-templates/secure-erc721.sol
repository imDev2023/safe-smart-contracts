// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title SecureERC721NFT
 * @author Smart Contract Security Best Practices
 * @notice Production-ready ERC721 (NFT) implementation with security features
 * @dev Implements ERC721 standard with the following features:
 *      - Enumerable extension for discovering all tokens
 *      - URI Storage for flexible metadata management
 *      - Burnable for token destruction
 *      - Ownable for administrative controls
 *      - Safe transfer patterns
 *      - Custom errors for gas efficiency
 *      - Counter library for token IDs
 *
 * Security Considerations:
 * - Uses OpenZeppelin's audited contracts
 * - SafeMint ensures recipient can receive NFTs
 * - Proper access controls on minting functions
 * - Token URI validation
 * - Locked pragma for reproducible builds
 */
contract SecureERC721NFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when attempting to mint to zero address
    error CannotMintToZeroAddress();

    /// @notice Thrown when token URI is empty
    error EmptyTokenURI();

    /// @notice Thrown when max supply is reached
    error MaxSupplyReached();

    /// @notice Thrown when invalid token ID is provided
    error InvalidTokenId();

    /// @notice Thrown when trying to set base URI to empty string
    error EmptyBaseURI();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Counter for token IDs
    /// @dev Starts at 1, increments for each new mint
    Counters.Counter private _tokenIdCounter;

    /// @notice Base URI for computing tokenURI
    /// @dev Can be updated by owner, concatenated with token ID
    string private _baseTokenURI;

    /// @notice Maximum number of NFTs that can be minted
    /// @dev Set to 10000 by default, can be modified in constructor
    uint256 public maxSupply;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new NFT is minted
    /// @param to Address receiving the minted NFT
    /// @param tokenId ID of the minted token
    /// @param tokenURI Metadata URI for the token
    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);

    /// @notice Emitted when base URI is updated
    /// @param newBaseURI New base URI value
    /// @param updatedBy Address that updated the base URI
    event BaseURIUpdated(string newBaseURI, address indexed updatedBy);

    /// @notice Emitted when token metadata URI is updated
    /// @param tokenId Token whose URI was updated
    /// @param newTokenURI New token URI
    event TokenURIUpdated(uint256 indexed tokenId, string newTokenURI);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the ERC721 NFT collection
     * @param name_ Collection name (e.g., "My NFT Collection")
     * @param symbol_ Collection symbol (e.g., "MNFT")
     * @param baseTokenURI_ Base URI for token metadata
     * @param maxSupply_ Maximum number of tokens that can be minted
     * @dev Token ID counter starts at 1
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        uint256 maxSupply_
    ) ERC721(name_, symbol_) {
        _baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;

        // Start token IDs at 1 instead of 0
        _tokenIdCounter.increment();
    }

    /*//////////////////////////////////////////////////////////////
                        MINTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints a new NFT to the specified address
     * @param to Address to receive the newly minted NFT
     * @param uri Metadata URI for this specific token
     * @dev Only callable by contract owner
     *      Uses safeMint to ensure recipient can handle NFTs
     *      Checks max supply constraint
     */
    function safeMint(address to, string memory uri) public onlyOwner {
        // Input validation
        if (to == address(0)) revert CannotMintToZeroAddress();
        if (bytes(uri).length == 0) revert EmptyTokenURI();

        // Check max supply
        uint256 currentSupply = _tokenIdCounter.current() - 1; // Subtract 1 because counter starts at 1
        if (currentSupply >= maxSupply) revert MaxSupplyReached();

        // Get next token ID
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Effects: mint token using safe mint (checks if recipient can receive)
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        // Emit event
        emit NFTMinted(to, tokenId, uri);
    }

    /**
     * @notice Batch mints multiple NFTs to the specified address
     * @param to Address to receive the newly minted NFTs
     * @param uris Array of metadata URIs for each token
     * @dev Only callable by contract owner
     *      More gas efficient than multiple single mints
     */
    function batchMint(address to, string[] memory uris) external onlyOwner {
        if (to == address(0)) revert CannotMintToZeroAddress();

        uint256 count = uris.length;
        uint256 currentSupply = _tokenIdCounter.current() - 1;

        if (currentSupply + count > maxSupply) revert MaxSupplyReached();

        for (uint256 i = 0; i < count; ) {
            if (bytes(uris[i]).length == 0) revert EmptyTokenURI();

            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uris[i]);

            emit NFTMinted(to, tokenId, uris[i]);

            unchecked {
                ++i; // Gas optimization: unchecked increment
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates the base URI for all token metadata
     * @param baseTokenURI_ New base URI
     * @dev Only callable by contract owner
     *      Individual token URIs are concatenated with this base URI
     */
    function setBaseURI(string memory baseTokenURI_) external onlyOwner {
        if (bytes(baseTokenURI_).length == 0) revert EmptyBaseURI();

        _baseTokenURI = baseTokenURI_;
        emit BaseURIUpdated(baseTokenURI_, msg.sender);
    }

    /**
     * @notice Updates the metadata URI for a specific token
     * @param tokenId Token ID to update
     * @param uri New metadata URI
     * @dev Only callable by contract owner
     *      Token must exist
     */
    function updateTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (bytes(uri).length == 0) revert EmptyTokenURI();

        _setTokenURI(tokenId, uri);
        emit TokenURIUpdated(tokenId, uri);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the base URI for token metadata
     * @return Base URI string
     */
    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Returns the current token ID counter value
     * @return Next token ID that will be minted
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @notice Returns remaining number of NFTs that can be minted
     * @return Number of remaining mintable tokens
     */
    function remainingSupply() external view returns (uint256) {
        uint256 currentSupply = _tokenIdCounter.current() - 1;
        return maxSupply > currentSupply ? maxSupply - currentSupply : 0;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to get base URI
     * @dev Overrides base ERC721 implementation
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Hook called before any token transfer
     * @dev Required override for Enumerable extension
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @notice Burns a token
     * @dev Required override for URIStorage extension
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * @notice Returns token URI
     * @dev Required override for URIStorage extension
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @notice Checks interface support
     * @dev Required override for Enumerable extension
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
