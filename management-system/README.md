# Decentralized Work Collaboration Smart Contract

# Overview
This Clarity smart contract implements a decentralized work collaboration platform on the Stacks blockchain. It allows for task management, member onboarding, fund allocation, and voting within a decentralized team structure.

## Features

- Member management (onboarding and offboarding)
- Task creation and progress tracking
- Fund allocation and withdrawal
- Voting system (basic structure)
- Role-based access control

## Prerequisites

- Clarity language knowledge
- Stacks blockchain environment
- Clarity CLI or Clarinet for testing and deployment

## Usage

After deployment, interact with the contract using a Stacks wallet or through API calls to the Stacks blockchain.

## Functions Overview

### Public Functions

1. `activate-contract`: Initializes the contract (admin only).
2. `onboard-new-member`: Adds a new member to the collaboration.
3. `offboard-member`: Removes a member from the collaboration.
4. `create-task`: Creates a new task with details and assigns an owner.
5. `update-task-progress`: Updates the progress state of a task.
6. `allocate-funds`: Allocates funds to a member (admin only).
7. `withdraw-funds`: Allows a member to withdraw their allocated funds.
8. `cast-vote`: Casts a vote on a proposal (voting logic to be implemented).

### Read-Only Functions

1. `get-member-profile`: Retrieves a member's profile information.
2. `get-task-details`: Retrieves details of a specific task.
3. `get-member-balance`: Retrieves the current balance of a member.
4. `get-current-contract-state`: Retrieves the current state of the contract.

## Error Codes

- `u100`: Access denied
- `u101`: Contract already active
- `u102`: Item not found
- `u103`: Invalid task state
- `u104`: Insufficient funds

## Contributing

Contributions to improve the smart contract are welcome. Please follow these steps:

1. Fork the repository
2. Create a new branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request