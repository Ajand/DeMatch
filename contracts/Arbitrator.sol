/**
 * SPDX-License-Identifier: MIT
 */
pragma solidity >=0.7;

import "./IArbitrator.sol";

contract Arbitrator is IArbitrator {
    address public owner = msg.sender;

    struct Dispute {
        IArbitrable arbitrated;
        uint256 choices;
        uint256 ruling;
        DisputeStatus status;
    }

    Dispute[] public disputes;

    function arbitrationCost(bytes memory _extraData)
        public
        pure
        override
        returns (uint256)
    {
        return 0.001 ether;
    }

    function appealCost(uint256 _disputeID, bytes memory _extraData)
        public
        pure
        override
        returns (uint256)
    {
        return 2**250; // An unaffordable amount which practically avoids appeals.
    }

    function createDispute(uint256 _choices, bytes memory _extraData)
        public
        payable
        override
        returns (uint256 disputeID)
    {
        require(
            msg.value >= arbitrationCost(_extraData),
            "Not enough ETH to cover arbitration costs."
        );

        disputes.push(
            Dispute({
                arbitrated: IArbitrable(msg.sender),
                choices: _choices,
                ruling: uint256(420),
                status: DisputeStatus.Waiting
            })
        );

        disputeID = disputes.length - 1;
        emit DisputeCreation(disputeID, IArbitrable(msg.sender));
    }

    function disputeStatus(uint256 _disputeID)
        public
        view
        override
        returns (DisputeStatus status)
    {
        status = disputes[_disputeID].status;
    }

    function currentRuling(uint256 _disputeID)
        public
        view
        override
        returns (uint256 ruling)
    {
        ruling = disputes[_disputeID].ruling;
    }

    function rule(uint256 _disputeID, uint256 _ruling) public {
        // For test reason everyone can arbitrate

        Dispute storage dispute = disputes[_disputeID];

        require(_ruling <= dispute.choices, "Ruling out of bounds!");
        require(
            dispute.status == DisputeStatus.Waiting,
            "Dispute is not awaiting arbitration."
        );

        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Solved;

        payable(msg.sender).transfer(arbitrationCost(""));
        dispute.arbitrated.rule(_disputeID, _ruling);
    }

    function appeal(uint256 _disputeID, bytes memory _extraData)
        public
        payable
        override
    {
        require(
            msg.value >= appealCost(_disputeID, _extraData),
            "Not enough ETH to cover arbitration costs."
        );
    }

    function appealPeriod(uint256 _disputeID)
        public
        pure
        override
        returns (uint256 start, uint256 end)
    {
        return (0, 0);
    }
}
