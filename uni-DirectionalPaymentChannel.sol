//Payment channels allow participants to repeatedly transfer Ether off chain.

//Here is how this contract is used:

//Alice deploys the contract, funding it with some Ether.
//Alice authorizes a payment by signing a message (off chain) and sends the signature to Bob.
//Bob claims his payment by presenting the signed message to the smart contract.
//If Bob does not claim his payment, Alice get her Ether back after the contract expires
//This is called a uni-directional payment channel since the payment can go only in a single direction from Alice to Bob.
pragma solidity ^0.7.6;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/cryptography/ECDSA.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/ReentrancyGuard.sol";

contract UniDirectionalPaymentChannel is ReentrancyGuard {
    using SafeMath for uint;
    using ECDSA for bytes32;

    address payable public payer;
    address payable public payee;

    uint public expiresAt;

    constructor(address payable _payee, uint _expiresAt) payable {
        require(_expiresAt > block.timestamp, "Expiration must be > now");

        payer = msg.sender;
        payee = _payee;
        expiresAt = _expiresAt;
    }

    function verify(
        bytes memory _signature,
        address _payer,
        address _contract,
        uint _payeeBalance
    ) public pure returns (bool) {
        // NOTE: sign with address of this contract to protect agains replay attack on other contracts
        return keccak256(abi.encodePacked(_contract, _payeeBalance)).toEthSignedMessageHash().recover(_signature) == _payer;
    }

    modifier checkSignature(bytes memory _signature, uint _payeeBalance) {
        require(
            verify(_signature, payer, address(this), _payeeBalance),
            "Invalid signature"
        );
        _;
    }

    function close(uint _payeeBalance, bytes memory _signature)
        public
        nonReentrant
        checkSignature(_signature, _payeeBalance)
    {
        require(msg.sender == payee, "Not payee");

        (bool sent, ) = payee.call{value: _payeeBalance}("");
        require(sent, "Failed to send Ether");
        selfdestruct(payer);
    }

    function kill() public {
        require(msg.sender == payer, "Not payer");
        require(block.timestamp >= expiresAt, "channel not expired");
        selfdestruct(payer);
    }
}
