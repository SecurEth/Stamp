pragma solidity ^0.4.19;

import "./zeppelin/ERC721.sol";

/**
 * @title ERC721Token
 * Generic implementation for the required functionality of the ERC721 standard
 */
contract ERC721Token is ERC721 {

  // Total amount of tokens
  uint256 private totalTokens;

  // Mapping from token ID to owner
  mapping (uint256 => address) private tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private tokenApprovals;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) private ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private ownedTokensIndex;

  // Mapping from token ID to audit data IPFS hash or URL
  mapping(uint256 => string) private auditDataLocation;

  /**
  * @dev Guarantees msg.sender is owner of the given token
  * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
  */
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
  * @dev Gets the total amount of tokens stored by the contract
  * @return uint256 representing the total amount of tokens
  */
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

  /**
  * @dev Gets the balance of the specified address
  * @param _owner address to query the balance of
  * @return uint256 representing the amount owned by the passed address
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

  /**
  * @dev Gets the owner of the specified token ID
  * @param _tokenId uint256 ID of the token to query the owner of
  * @return owner address currently marked as the owner of the given token ID
  */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
  * @dev Mint token function
  * @param _to The address that will own the minted token
  * @param _tokenId uint256 ID of the token to be minted by the msg.sender
  */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

  /**
  * @dev Internal function to add a token ID to the list of a given address
  * @param _to address representing the new owner of the given token ID
  * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
  */
  function addToken(address _to, uint256 _tokenId) private {
	require(totalTokens + 1 < totalTokens); // Mitigates overflow
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens += 1; // Mitigated by input check, removes SafeMath dependancy
  }

  /**
  * @dev Gets the location of the audit data for a given token
  * @param _tokenId uint256 ID of the token to get the data location for
  */
  function tokenMetadata(uint256 _tokenId) public constant returns (string auditDataURL) {
    return auditDataLocation[_tokenId];
  }

  /**
  * @dev Internal function to set the location of the audit data for a given token
  * @param _tokenId uint256 ID of the token to get the data location for
  * @param _auditDataURL string the data location to set for given token
  */
  function _setTokenMetadata(uint256 _tokenId, string _auditDataURL) internal {
    auditDataLocation[_tokenId] = _auditDataURL;
  }
 
  /**
   * @dev We do not implement this function
   */ 
  function transfer(address _to, uint256 _tokenId) public { }
 
  /**
   * @dev We do not implement this function
   */ 
  function approve(address _to, uint256 _tokenId) public { }
 
  /**
   * @dev We do not implement this function
   */ 
  function takeOwnership(uint256 _tokenId) public { }
}

/**
 * @title Stamp
 * Rubber stamp, minting powers is managed by authority
 */
contract Stamp is ERC721Token {

  // The administrator of the approval list
  address public admin;

  // The approved parties that can mint new tokens
  mapping (address => bool) public approvedToMint;

  function approveMinter(address _minter) public {
    require(msg.sender == admin);
    approvedToMint[_minter] = true;
  }

  function banMinter(address _minter) public {
    require(msg.sender == admin);
    approvedToMint[_minter] = false;
  }
  
  /**
   * @dev Allows an approved party to mint a new audit stamp token
   * @param _to address the destination for the audit stamp
   * @param _auditDataURL string the data location to set for given token
   */
  function mint(address _to, string _auditDataURL) public {
    require(approvedToMint[msg.sender]);

    uint256 _tokenId = totalSupply(); // Capture this for below
    _mint(_to, _tokenId); // Mint a new token (changes totalTokens)
    _setTokenMetadata(_tokenId, _auditDataURL); // Set the metadata for that token
  }
}
