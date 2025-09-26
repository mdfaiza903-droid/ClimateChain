
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ClimateChain
 * @dev A decentralized platform for carbon credit management, climate action tracking, and environmental impact verification
 * @author ClimateChain Team
 */
contract Project {
    // State variables
    address public owner;
    uint256 public totalCarbonCredits;
    uint256 public totalProjects;
    uint256 public totalParticipants;
    
    // Structs
    struct CarbonCredit {
        uint256 id;
        address issuer;
        string projectName;
        uint256 amount; // in tonnes of CO2
        uint256 pricePerTonne; // in wei
        bool isVerified;
        bool isRetired;
        address currentOwner;
        uint256 issuedAt;
        string verificationHash; // IPFS hash for verification documents
        string methodology; // Carbon offset methodology used
    }
    
    struct ClimateProject {
        uint256 id;
        address owner;
        string name;
        string description;
        string location;
        uint256 targetCO2Reduction; // in tonnes
        uint256 currentCO2Reduction; // in tonnes
        uint256 fundingGoal; // in wei
        uint256 currentFunding; // in wei
        bool isActive;
        bool isVerified;
        uint256 createdAt;
        string[] milestones;
        mapping(address => uint256) contributors;
        address[] contributorList;
    }
    
    struct Participant {
        address participantAddress;
        string name;
        string organizationType; // Individual, NGO, Corporation, Government
        uint256 carbonCreditsOwned;
        uint256 carbonCreditsRetired;
        uint256 totalContributions;
        uint256 projectsSupported;
        bool isVerified;
        uint256 registeredAt;
        string verificationDocuments; // IPFS hash
    }
    
    // Mappings
    mapping(uint256 => CarbonCredit) public carbonCredits;
    mapping(uint256 => ClimateProject) public climateProjects;
    mapping(address => Participant) public participants;
    mapping(uint256 => address[]) public projectContributors;
    mapping(address => uint256[]) public userCarbonCredits;
    mapping(address => bool) public verifiedIssuers;
    
    // Events
    event ParticipantRegistered(address indexed participant, string name, string organizationType);
    event CarbonCreditIssued(uint256 indexed creditId, address issuer, uint256 amount, uint256 price);
    event CarbonCreditTransferred(uint256 indexed creditId, address from, address to);
    event CarbonCreditRetired(uint256 indexed creditId, address owner);
    event ClimateProjectCreated(uint256 indexed projectId, string name, address owner, uint256 fundingGoal);
    event ProjectFunded(uint256 indexed projectId, address contributor, uint256 amount);
    event ProjectVerified(uint256 indexed projectId, address verifier);
    event MilestoneAchieved(uint256 indexed projectId, string milestone);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyVerifiedIssuer() {
        require(verifiedIssuers[msg.sender], "Only verified issuers can issue credits");
        _;
    }
    
    modifier onlyRegisteredParticipant() {
        require(participants[msg.sender].participantAddress != address(0), "Participant must be registered");
        _;
    }
    
    modifier creditExists(uint256 _creditId) {
        require(_creditId <= totalCarbonCredits && carbonCredits[_creditId].id != 0, "Carbon credit does not exist");
        _;
    }
    
    modifier projectExists(uint256 _projectId) {
        require(_projectId <= totalProjects && climateProjects[_projectId].id != 0, "Project does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        totalCarbonCredits = 0;
        totalProjects = 0;
        totalParticipants = 0;
        verifiedIssuers[msg.sender] = true; // Owner is automatically a verified issuer
    }
    
    /**
     * @dev Core Function 1: Register as a participant in the climate action ecosystem
     * @param _name Name of the participant/organization
     * @param _organizationType Type of organization (Individual, NGO, Corporation, Government)
     * @param _verificationDocuments IPFS hash of verification documents
     */
    function registerParticipant(
        string memory _name,
        string memory _organizationType,
        string memory _verificationDocuments
    ) external {
        require(participants[msg.sender].participantAddress == address(0), "Participant already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_organizationType).length > 0, "Organization type cannot be empty");
        
        participants[msg.sender] = Participant({
            participantAddress: msg.sender,
            name: _name,
            organizationType: _organizationType,
            carbonCreditsOwned: 0,
            carbonCreditsRetired: 0,
            totalContributions: 0,
            projectsSupported: 0,
            isVerified: false,
            registeredAt: block.timestamp,
            verificationDocuments: _verificationDocuments
        });
        
        totalParticipants++;
        emit ParticipantRegistered(msg.sender, _name, _organizationType);
    }
    
    /**
     * @dev Core Function 2: Issue verified carbon credits from environmental projects
     * @param _projectName Name of the project generating credits
     * @param _amount Amount of CO2 offset in tonnes
     * @param _pricePerTonne Price per tonne in wei
     * @param _verificationHash IPFS hash of verification documents
     * @param _methodology Carbon offset methodology used
     */
    function issueCarbonCredits(
        string memory _projectName,
        uint256 _amount,
        uint256 _pricePerTonne,
        string memory _verificationHash,
        string memory _methodology
    ) external onlyVerifiedIssuer onlyRegisteredParticipant {
        require(_amount > 0, "Amount must be greater than 0");
        require(_pricePerTonne > 0, "Price must be greater than 0");
        require(bytes(_projectName).length > 0, "Project name cannot be empty");
        require(bytes(_verificationHash).length > 0, "Verification hash required");
        
        totalCarbonCredits++;
        
        carbonCredits[totalCarbonCredits] = CarbonCredit({
            id: totalCarbonCredits,
            issuer: msg.sender,
            projectName: _projectName,
            amount: _amount,
            pricePerTonne: _pricePerTonne,
            isVerified: true, // Auto-verified since only verified issuers can call this
            isRetired: false,
            currentOwner: msg.sender,
            issuedAt: block.timestamp,
            verificationHash: _verificationHash,
            methodology: _methodology
        });
        
        // Update issuer's carbon credits
        userCarbonCredits[msg.sender].push(totalCarbonCredits);
        participants[msg.sender].carbonCreditsOwned += _amount;
        
        emit CarbonCreditIssued(totalCarbonCredits, msg.sender, _amount, _pricePerTonne);
    }
    
    /**
     * @dev Core Function 3: Create and fund climate action projects
     * @param _name Project name
     * @param _description Project description
     * @param _location Project location
     * @param _targetCO2Reduction Target CO2 reduction in tonnes
     * @param _fundingGoal Funding goal in wei
     */
    function createClimateProject(
        string memory _name,
        string memory _description,
        string memory _location,
        uint256 _targetCO2Reduction,
        uint256 _fundingGoal
    ) external onlyRegisteredParticipant {
        require(bytes(_name).length > 0, "Project name cannot be empty");
        require(_targetCO2Reduction > 0, "Target CO2 reduction must be greater than 0");
        require(_fundingGoal > 0, "Funding goal must be greater than 0");
        
        totalProjects++;
        
        ClimateProject storage newProject = climateProjects[totalProjects];
        newProject.id = totalProjects;
        newProject.owner = msg.sender;
        newProject.name = _name;
        newProject.description = _description;
        newProject.location = _location;
        newProject.targetCO2Reduction = _targetCO2Reduction;
        newProject.currentCO2Reduction = 0;
        newProject.fundingGoal = _fundingGoal;
        newProject.currentFunding = 0;
        newProject.isActive = true;
        newProject.isVerified = false;
        newProject.createdAt = block.timestamp;
        
        emit ClimateProjectCreated(totalProjects, _name, msg.sender, _fundingGoal);
    }
    
    /**
     * @dev Fund a climate project
     * @param _projectId ID of the project to fund
     */
    function fundProject(uint256 _projectId) external payable projectExists(_projectId) onlyRegisteredParticipant {
        require(msg.value > 0, "Funding amount must be greater than 0");
        ClimateProject storage project = climateProjects[_projectId];
        require(project.isActive, "Project is not active");
        require(project.currentFunding < project.fundingGoal, "Project is already fully funded");
        
        // Add contributor if first time contributing
        if (project.contributors[msg.sender] == 0) {
            project.contributorList.push(msg.sender);
            participants[msg.sender].projectsSupported++;
        }
        
        project.contributors[msg.sender] += msg.value;
        project.currentFunding += msg.value;
        participants[msg.sender].totalContributions += msg.value;
        
        // Transfer funds to project owner
        payable(project.owner).transfer(msg.value);
        
        emit ProjectFunded(_projectId, msg.sender, msg.value);
        
        // Check if funding goal is reached
        if (project.currentFunding >= project.fundingGoal) {
            // Project can now begin implementation
        }
    }
    
    /**
     * @dev Purchase and transfer carbon credits
     * @param _creditId ID of the carbon credit to purchase
     */
    function purchaseCarbonCredits(uint256 _creditId) external payable creditExists(_creditId) onlyRegisteredParticipant {
        CarbonCredit storage credit = carbonCredits[_creditId];
        require(!credit.isRetired, "Carbon credit has been retired");
        require(credit.currentOwner != msg.sender, "Cannot purchase your own credits");
        
        uint256 totalPrice = credit.amount * credit.pricePerTonne;
        require(msg.value >= totalPrice, "Insufficient payment");
        
        address previousOwner = credit.currentOwner;
        
        // Remove from previous owner
        _removeCreditFromOwner(previousOwner, _creditId);
        participants[previousOwner].carbonCreditsOwned -= credit.amount;
        
        // Add to new owner
        credit.currentOwner = msg.sender;
        userCarbonCredits[msg.sender].push(_creditId);
        participants[msg.sender].carbonCreditsOwned += credit.amount;
        
        // Transfer payment to previous owner
        payable(previousOwner).transfer(totalPrice);
        
        // Refund excess payment
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        
        emit CarbonCreditTransferred(_creditId, previousOwner, msg.sender);
    }
    
    /**
     * @dev Retire carbon credits to offset carbon footprint
     * @param _creditId ID of the carbon credit to retire
     */
    function retireCarbonCredits(uint256 _creditId) external creditExists(_creditId) {
        CarbonCredit storage credit = carbonCredits[_creditId];
        require(credit.currentOwner == msg.sender, "Only owner can retire credits");
        require(!credit.isRetired, "Credit already retired");
        
        credit.isRetired = true;
        participants[msg.sender].carbonCreditsOwned -= credit.amount;
        participants[msg.sender].carbonCreditsRetired += credit.amount;
        
        // Remove from owner's active credits
        _removeCreditFromOwner(msg.sender, _creditId);
        
        emit CarbonCreditRetired(_creditId, msg.sender);
    }
    
    // Internal function to remove credit from owner's list
    function _removeCreditFromOwner(address _owner, uint256 _creditId) internal {
        uint256[] storage ownerCredits = userCarbonCredits[_owner];
        for (uint i = 0; i < ownerCredits.length; i++) {
            if (ownerCredits[i] == _creditId) {
                ownerCredits[i] = ownerCredits[ownerCredits.length - 1];
                ownerCredits.pop();
                break;
            }
        }
    }
    
    // Owner functions
    function addVerifiedIssuer(address _issuer) external onlyOwner {
        verifiedIssuers[_issuer] = true;
    }
    
    function removeVerifiedIssuer(address _issuer) external onlyOwner {
        verifiedIssuers[_issuer] = false;
    }
    
    function verifyParticipant(address _participant) external onlyOwner {
        require(participants[_participant].participantAddress != address(0), "Participant not registered");
        participants[_participant].isVerified = true;
    }
    
    function verifyProject(uint256 _projectId) external onlyOwner projectExists(_projectId) {
        climateProjects[_projectId].isVerified = true;
        emit ProjectVerified(_projectId, msg.sender);
    }
    
    function updateProjectProgress(uint256 _projectId, uint256 _co2Reduced) external onlyOwner projectExists(_projectId) {
        ClimateProject storage project = climateProjects[_projectId];
        require(_co2Reduced <= project.targetCO2Reduction, "Cannot exceed target");
        project.currentCO2Reduction = _co2Reduced;
    }
    
    // View functions
    function getCarbonCredit(uint256 _creditId) external view creditExists(_creditId) returns (CarbonCredit memory) {
        return carbonCredits[_creditId];
    }
    
    function getParticipant(address _participant) external view returns (Participant memory) {
        return participants[_participant];
    }
    
    function getUserCarbonCredits(address _user) external view returns (uint256[] memory) {
        return userCarbonCredits[_user];
    }
    
    function getProjectContributors(uint256 _projectId) external view projectExists(_projectId) returns (address[] memory) {
        return climateProjects[_projectId].contributorList;
    }
    
    function getProjectContribution(uint256 _projectId, address _contributor) external view projectExists(_projectId) returns (uint256) {
        return climateProjects[_projectId].contributors[_contributor];
    }
    
    function getPlatformStats() external view returns (uint256, uint256, uint256, uint256) {
        return (totalCarbonCredits, totalProjects, totalParticipants, address(this).balance);
    }
    
    function isVerifiedIssuer(address _issuer) external view returns (bool) {
        return verifiedIssuers[_issuer];
    }
}
