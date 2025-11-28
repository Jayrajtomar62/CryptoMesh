// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

 /**
  * @title CryptoMesh
  * @dev A decentralized payment and reputation system for mesh network nodes.
  * Nodes earn tokens by relaying packets and build reputation based on reliability.
  */
contract CryptoMesh {
    string public constant NAME = "CryptoMesh";
    string public constant VERSION = "1.0.0";

    // Node structure
    struct Node {
        uint256 reputation;     // Reputation score (0-10000, higher = more trusted)
        uint256 totalRelayed;   // Total packets relayed
        uint256 balance;        // Token balance for payouts
        bool registered;
    }

    mapping(address => Node) public nodes;
    address[] public nodeList;

    // Events
    event NodeRegistered(address indexed node);
    event PacketRelayed(address indexed from, address indexed to, uint256 value, uint256 packetId);
    event RewardClaimed(address indexed node, uint256 amount);
    event ReputationUpdated(address indexed node, uint256 newReputation);

    // Owner (for future governance)
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Register a new mesh node
     */
    function registerNode() external {
        require(!nodes[msg.sender].registered, "Already registered");

        nodes[msg.sender] = Node({
            reputation: 1000,     // Starting reputation (out of 10000)
            totalRelayed: 0,
            balance: 0,
            registered: true
        });

        nodeList.push(msg.sender);
        emit NodeRegistered(msg.sender);
    }

    /**
     * @dev Relay a packet: sender pays receiver for forwarding data
     * @param packetId Unique packet identifier
     */
    function relayPacket(uint256 packetId) external payable {
        require(nodes[msg.sender].registered, "Sender not registered");
        require(msg.value > 0, "Must send ETH/BNB/MATIC");

        // In a real mesh, the next hop is determined off-chain.
        // Here we assume the caller is paying themselves as the next hop for simplicity.
        // In production, this would be called by a router contract or use signed messages.

        nodes[msg.sender].totalRelayed += 1;
        nodes[msg.sender].balance += msg.value;

        // Simple reputation boost (max 10000)
        if (nodes[msg.sender].reputation < 10000) {
            nodes[msg.sender].reputation += 10;
            emit ReputationUpdated(msg.sender, nodes[msg.sender].reputation);
        }

        emit PacketRelayed(msg.sender, msg.sender, msg.value, packetId);
    }

    /**
     * @dev Claim accumulated rewards
     */
    function claimRewards() external {
        require(nodes[msg.sender].registered, "Not registered");
        uint256 amount = nodes[msg.sender].balance;
        require(amount > 0, "No rewards to claim");

        nodes[msg.sender].balance = 0;
        payable(msg.sender).transfer(amount);

        emit RewardClaimed(msg.sender, amount);
    }

    /**
     * @dev Get node info
     */
    function getNode(address node) external view returns (Node memory) {
        return nodes[node];
    }

    /**
     * @dev Get total registered nodes count
     */
    function totalNodes() external view returns (uint256) {
        return nodeList.length;
    }
}
