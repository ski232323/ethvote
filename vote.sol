// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVotes {
    function getVotes(address account) external view returns (uint256);
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);
}

contract SimpleVoting {
    IVotes public token;
    address public owner;
    bool public votingEnded;

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    Proposal[] public proposals;

    mapping(address => bool) public hasVoted;

    uint256 public votingBlock; // bloc où on prend le snapshot de la supply

    constructor(address tokenAddress, string[] memory proposalDescriptions) {
        owner = msg.sender;
        token = IVotes(tokenAddress);
        for (uint i = 0; i < proposalDescriptions.length; i++) {
            proposals.push(Proposal({
                description: proposalDescriptions[i],
                voteCount: 0
            }));
        }
        votingBlock = block.number;
        votingEnded = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier voteAllowed() {
        require(!votingEnded, "Voting has ended");
        _;
    }

    function vote(uint proposalId) public voteAllowed {
        require(!hasVoted[msg.sender], "Already voted");
        uint256 voterPower = token.getVotes(msg.sender);
        require(voterPower > 0, "No voting power");
        proposals[proposalId].voteCount += voterPower;
        hasVoted[msg.sender] = true;
    }

    /// @notice Terminer le vote (seulement propriétaire)
    function endVoting() public onlyOwner {
        votingEnded = true;
    }

    /// @notice Renvoie l'index de la proposition gagnante (celle avec le plus de votes)
    function winningProposal() public view returns (uint winningProposalId) {
        uint highestVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > highestVoteCount) {
                highestVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
    }

    /// @notice Vérifie si une proposition a la majorité absolue (>50%)
    function isMajority(uint proposalId) public view returns (bool) {
        uint totalSupplyAtVote = token.getPastTotalSupply(votingBlock);
        return proposals[proposalId].voteCount > totalSupplyAtVote / 2;
    }

    function getProposal(uint proposalId) public view returns (string memory description, uint256 voteCount) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.description, proposal.voteCount);
    }

    function getProposalsCount() public view returns (uint) {
        return proposals.length;
    }
}
