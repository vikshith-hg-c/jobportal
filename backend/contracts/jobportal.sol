// SPDX-License-Identifier: unlicensed
pragma solidity >=0.8.2 <0.9.0;


contract jobPortal{
    address ADMIN;
    enum rating{A,B,C,D,E,NotRated}
    uint public employeeCount;
    uint public employerCount;
    uint public jobCount;
    uint public openTransactions;


    struct employee{
        string name;
        uint256 KYC_UID;
        rating Rating;
        uint8 experence;
        bool status;
        address payable wallet;
        uint currentJobId;
    
    }
 
    struct employer{
        string name;
        uint256 KYC_UID;
        address payable wallet;
    }

    struct job{
        uint jobId;
        string titile;
        uint256 timeInDays;
        bool status;
        address payable jobOwner;
    }
    
    mapping(address => employee) public employeeList;  //employee address => employee details
    address[] public employees;
    mapping(address => employer) public employerList;  //employee address => employee details
    address[] public employers; // all employers list 
    mapping(uint => job) public jobList;    //jobId => job detsils 
    mapping(address => uint[]) public employersWisejobID; // employers => all posted jobIds
    mapping(address => mapping (uint => address[]))jobApplications; // employers => jobId => all applicants address 
    mapping(uint => mapping(address => bool)) public joboffer; // jobid => applicant address => true:offer || false :reject
    mapping(address => uint[]) public appliedJobs; // employee => applied JobId's
    mapping(uint => address)worker; // jobid ==> worker confirmed on JOB

    event eventAddEmployee(address indexed _employeeAddress, string _name, uint256 _KYC_UID);
    event eventAddEmployer(address indexed _employerAddress, string _name, uint256 _KYC_UID);
    event jobPost(uint indexed _jobId,address indexed _jobOwner,string _titile);
    event jobOfferStatus(address indexed _employer,address indexed _employee,uint _jobId,bool _status);
    event jobAccepted(address indexed _employee,uint _jobId);

    constructor() {
        ADMIN = msg.sender; 
        employeeCount = 0;
        employerCount = 0;
        jobCount = 0;
        openTransactions = 0;
    }

    function addEmployee(string memory _name,uint256 _KYC_UID, uint8 _experence,address payable _wallet) _isAdmin _ifEmployeeExist(_wallet) external {
        employeeCount += 1;
        employeeList[_wallet].name = _name;
        employeeList[_wallet].KYC_UID= _KYC_UID; 
        employeeList[_wallet].Rating = rating.NotRated;
        employeeList[_wallet].experence =_experence;
        employeeList[_wallet].status = true;
        employeeList[_wallet].wallet = payable(_wallet);
        employeeList[_wallet].currentJobId = 0;
        employees.push(_wallet);
        emit eventAddEmployee(_wallet, _name,_KYC_UID);   
    }

    function addEmployer(string memory _name,uint256 _KYC_UID,address payable _wallet) _isAdmin _ifEmployerExist(_wallet)external {
        employerCount += 1;
        employers.push(msg.sender);
        employerList[_wallet].name = _name;
        employerList[_wallet].KYC_UID = _KYC_UID;
        employerList[_wallet].wallet = _wallet;
        emit eventAddEmployer(_wallet, _name,_KYC_UID);   
    }
   
    function postJob(string memory _titile, uint8 _timeInDays) _isEmployer() public  {
        jobCount += 1;
        jobList[jobCount].jobId = jobCount;
        jobList[jobCount].titile = _titile;
        jobList[jobCount].timeInDays = _timeInDays;
        jobList[jobCount].status = true;
        jobList[jobCount].jobOwner = payable(msg.sender);
        employersWisejobID[msg.sender].push(jobCount);
        emit jobPost(jobCount,msg.sender,_titile);
    }

    function getjob(uint _jobId) _isEmployee external view returns  (string memory,uint){
        return(jobList[_jobId].titile,jobList[_jobId].timeInDays);
    }

    function applyjob(uint _jobId) _isEmployee external {
        openTransactions+= 1;
        address _employer;
        _employer = jobList[_jobId].jobOwner;
        jobApplications[_employer][_jobId].push(msg.sender);
        appliedJobs[msg.sender].push(_jobId);

    }

    function getApplicants(uint _jobId) _isEmployer external view returns(address[] memory) {
        return(jobApplications[msg.sender][_jobId]);
    }

    function applicantDetails(address _address) _isEmployer external view returns(string memory,uint256,rating,uint,bool,address) {
        return(
            employeeList[_address].name,
            employeeList[_address].KYC_UID,
            employeeList[_address].Rating,
            employeeList[_address].experence,
            employeeList[_address].status,
            employeeList[_address].wallet
        );
    }
    
    function applicationAction(uint _jobId, address _employee,bool _action) _isJobOwner(_jobId) _isEmployer external {
        
        for(uint i = 0; i< jobApplications[msg.sender][_jobId].length;i++ ){
            if(jobApplications[msg.sender][_jobId][i] == _employee){
                joboffer[_jobId][_employee] = _action;
                emit jobOfferStatus(msg.sender,_employee,_jobId,_action);
            }
            else {continue;}
        }
        if (!_action){openTransactions-= 1;}
        
    }

    function acceptJob(uint _jobId) _isEmployee() _isApplicant(_jobId) external {
        employeeList[msg.sender].currentJobId = _jobId;
        employeeList[msg.sender].status = false;
        worker[_jobId] = msg.sender;
        emit jobAccepted(msg.sender,_jobId);

    }

    function rateEmployee(uint _jobId,uint _rating,address _employee) _isEmployer _isJobOwner(_jobId) _isWorker(_jobId,_employee) external {
        
        if (_rating == 5 ){employeeList[_employee].Rating =  rating.A;}else
        if (_rating == 4 ){employeeList[_employee].Rating =  rating.B;}else
        if (_rating == 3 ){employeeList[_employee].Rating =  rating.C;}else
        if (_rating == 2 ){employeeList[_employee].Rating =  rating.D;}else
        if (_rating == 1 ){employeeList[_employee].Rating =  rating.E;}
        else {revert("Rate in scale of 1 to 5");
        }
        employeeList[_employee].currentJobId = 0;
        openTransactions-= 1;
    }

    modifier _isEmployee(){
        require(employeeList[msg.sender].wallet == msg.sender, "access denied");
        _;
    }

    modifier _isEmployer(){
        require(employerList[msg.sender].wallet == msg.sender, "access denied");
        _;
    }

    modifier _isAdmin(){
        require(ADMIN == msg.sender, "access denied");
        _;
    }
    
    modifier _isJobOwner(uint _jobId){
        require(jobList[_jobId].jobOwner == msg.sender , "access denied");
        _;
    }

    modifier _isApplicant(uint _jobId){
        bool isValid;
        for(uint i = 0 ; i < appliedJobs[msg.sender].length ; i++ )
        {
            if(appliedJobs[msg.sender][i] == _jobId) { isValid = true;} else {continue;}
        
        }
        require(isValid,"illegal operation"); 
        _;
    }

    modifier _isWorker(uint _jobId, address _employee){
        require(worker[_jobId] == _employee, "Rating wrong worker");
        _;
    }

    modifier _ifEmployeeExist(address _wallet){
        bool isValid = true;
        for (uint i = 0; i< employees.length;i++)
        {
            if(employees[i] == _wallet)
            {isValid = false;}
            else {continue;}
        }require(isValid,"Employee Already Exist");
        _;
    }

    modifier _ifEmployerExist(address _wallet){
        bool isValid = true;
        for (uint i = 0; i < employers.length; i++)
        {
            if(employers[i] == _wallet)
            {isValid = false;}
            else {continue;}
        }require(isValid,"Employer Already Exist");
        _;
    }
   
   
}