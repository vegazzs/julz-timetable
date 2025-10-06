//SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

/**
 * @title Julz timetable
 * @author Vegas
 * @notice A smart contract that contains Julz ICAN reading timetable and mock exams
 */
contract JulzTimetable {
    //errors
    error Not_Owner();
    error Invalid_Week();
    error Invalid_Day();
    error Day_Already_Set();
    error Day_Not_Set();
    error Day_Already_Completed();
    //for exam days
    error Exam_Already_Set();
    error Not_Exam_Day();
    error Exam_Already_Started();

    //state variables
    address public owner;
    string public candidateName;

    //enums
    enum DayType {
        none,
        read,
        exam
    }

    struct Day {
        DayType dayType;
        bool isSet;
        bool isCompleted;
        string subject;
        string[] topics;
        string time;
        //for exams
        string title;
        string[] questions;
        string grade;
        uint256 startTime;
        uint256 duration;
        string ipfsLink;
    }

    struct Week {
        mapping(uint8 => Day) day;
    }

    mapping(uint8 => Week) week;

    //events
    event subjectSet(uint8 weekNumber, uint8 dayNumber);
    event DayCompleted(uint8 weekNumber, uint8 dayNumber);
    event DayRemoved(uint8 weekNumber, uint8 dayNumber);
    event DayCompletedUnmarked(uint8 weekNumber, uint8 dayNumber);
    //for exams
    event ExamCompleted(uint8 weekNumber, uint8 dayNumber, string grade, string ipfsLink);
    event ExamSet(uint8 weekNumber, uint8 dayNumber);
    event ExamStarted(uint8 weekNumber, uint8 dayNumber);

    constructor() {
        owner = msg.sender;

        candidateName = "JULIET ONYINYE O";
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Not_Owner();
        _;
    }

    //////////////////////////////////////////////////////////////
    //                 SET  READING DAY                         //
    //////////////////////////////////////////////////////////////
    function setReadingDay(
        uint8 weekNumber,
        uint8 dayNumber,
        string memory subject,
        string[] memory topics,
        string memory time
    ) external onlyOwner {
        //checks
        if (weekNumber < 1 || weekNumber > 6) {
            revert Invalid_Week();
        }
        if (dayNumber < 1 || dayNumber > 6) {
            revert Invalid_Day();
        }

        Day storage _day = week[weekNumber].day[dayNumber];
        if (_day.isSet) {
            revert Day_Already_Set();
        }

        _day.dayType = DayType.read;
        _day.subject = subject;
        _day.topics = topics;
        _day.time = time;
        _day.isCompleted = false;

        emit subjectSet(weekNumber, dayNumber);
    }

    //////////////////////////////////////////////////////////////
    //                   SET EXAM DAY                           //
    //////////////////////////////////////////////////////////////
    function setExamDay(uint8 weekNumber, uint8 dayNumber, string memory title, string[] memory questions)
        external
        onlyOwner
    {
        //checks
        if (weekNumber < 1 || weekNumber > 6) {
            revert Invalid_Week();
        }
        if (dayNumber < 7 || dayNumber > 7) {
            revert Invalid_Day();
        }

        Day storage exam = week[weekNumber].day[dayNumber];
        if (exam.isSet) {
            revert Exam_Already_Set();
        }
        exam.dayType = DayType.exam;
        exam.title = title;
        exam.questions = questions;
        exam.duration = 180 minutes;
        exam.startTime = 0;
        exam.isCompleted = false;

        delete exam.grade;

        emit ExamSet(weekNumber, dayNumber);
    }
    //////////////////////////////////////////////////////////////
    //                      START EXAM                         //
    //////////////////////////////////////////////////////////////
    // Add this function to your new smart contract:

    function startExamDay(uint8 weekNumber, uint8 dayNumber) external {
        // 1. Basic Checks
        if (weekNumber < 1 || weekNumber > 6) {
            revert Invalid_Week();
        }
        if (dayNumber < 1 || dayNumber > 7) {
            revert Invalid_Day();
        }

        Day storage exam = week[weekNumber].day[dayNumber];

        // 2. State Checks
        if (exam.dayType != DayType.exam) {
            revert Not_Exam_Day();
        }
        // Check if exam has already started (startTime > 0)
        if (exam.startTime > 0) {
            revert Exam_Already_Started();
        }
        if (exam.isCompleted) {
            revert Day_Already_Completed();
        }

        // 3. Set the official start time
        exam.startTime = block.timestamp;
        exam.duration = 180 minutes;

        emit ExamStarted(weekNumber, dayNumber);
    }

    //////////////////////////////////////////////////////////////
    //                MARK DAY COMPLETED                        //
    //////////////////////////////////////////////////////////////
    function markDayCompleted(uint8 weekNumber, uint8 dayNumber, string memory grade, string memory ipfsLink)
        external
        onlyOwner
    {
        if (weekNumber < 1 || weekNumber > 6) {
            revert Invalid_Week();
        }
        if (dayNumber < 1 || dayNumber > 7) {
            revert Invalid_Day();
        }

        Day storage _day = week[weekNumber].day[dayNumber];

        if (_day.dayType == DayType.none) {
            revert Day_Not_Set();
        }
        if (_day.isCompleted) {
            revert Day_Already_Completed();
        }

        _day.isCompleted = true;

        if (_day.dayType == DayType.exam) {
            _day.grade = grade;
            _day.ipfsLink = ipfsLink;
            emit ExamCompleted(weekNumber, dayNumber, grade, ipfsLink);
        } else if (_day.dayType == DayType.read) {
            emit DayCompleted(weekNumber, dayNumber);
        }
    }

    function unmarkDayCompleted(uint8 weekNumber, uint8 dayNumber) external onlyOwner {
        if (weekNumber < 1 || weekNumber > 6) {
            revert Invalid_Week();
        }
        if (dayNumber < 1 || dayNumber > 7) {
            revert Invalid_Day();
        }

        Day storage _day = week[weekNumber].day[dayNumber];
        if (_day.dayType == DayType.none) {
            revert Day_Not_Set();
        }

        _day.isCompleted = false;

        emit DayCompletedUnmarked(weekNumber, dayNumber);
    }

    //////////////////////////////////////////////////////////////
    //                     REMOVE DAY                           //
    //////////////////////////////////////////////////////////////
    function removeDay(uint8 weekNumber, uint8 dayNumber) external onlyOwner {
        if (weekNumber < 1 || weekNumber > 6) {
            revert Invalid_Week();
        }
        if (dayNumber < 1 || dayNumber > 7) {
            revert Invalid_Day();
        }

        Day storage _day = week[weekNumber].day[dayNumber];
        if (_day.dayType == DayType.none) {
            revert Day_Not_Set();
        }

        delete week[weekNumber].day[dayNumber];

        emit DayRemoved(weekNumber, dayNumber);
    }

    //////////////////////////////////////////////////////////////
    //                      GET TODAY                           //
    //////////////////////////////////////////////////////////////
    function getToday(uint8 weekNumber, uint8 dayNumber)
        external
        view
        returns (
            DayType dayType,
            string memory subject,
            string memory title,
            string[] memory topics,
            string[] memory questions,
            string memory grade,
            string memory time,
            uint256 startTime,
            uint256 duration,
            bool isCompleted,
            string memory ipfsLink
        )
    {
        if (weekNumber < 1 || weekNumber > 6) {
            revert Invalid_Week();
        }
        if (dayNumber < 1 || dayNumber > 7) {
            revert Invalid_Day();
        }

        Day storage _day = week[weekNumber].day[dayNumber];

        if (_day.dayType == DayType.none) {
            revert Day_Not_Set();
        }
        dayType = _day.dayType;
        isCompleted = _day.isCompleted;

        if (_day.dayType == DayType.read) {
            subject = _day.subject;
            topics = _day.topics;
            time = _day.time;
            return (dayType, subject, "", topics, new string[](0), "", time, 0, 0, isCompleted, "");
        } else if (_day.dayType == DayType.exam) {
            title = _day.title;
            startTime = _day.startTime;
            duration = _day.duration;
            if (_day.isCompleted) {
                grade = _day.grade;
                ipfsLink = _day.ipfsLink;
                return (
                    dayType, "", title, new string[](0), new string[](0), grade, "", startTime, duration, true, ipfsLink
                );
            } else {
                questions = _day.questions;
                return (dayType, "", title, new string[](0), questions, "", "", startTime, duration, false, "");
            }
        }
        revert Day_Not_Set();
    }

    //////////////////////////////////////////////////////////////
    //                GET COMPLETED STATS                       //
    //////////////////////////////////////////////////////////////
    function getCompletionStats() external view returns (uint8 completedDays, uint8 totalDays, uint256 percentage) {
        totalDays = 42;
        completedDays = 0;

        // 💡 CRITICAL FIX: Loop from i=1 to 6 and j=1 to 7 💡
        for (uint8 i = 1; i <= 6; i++) {
            // Start at 1, go through 6
            for (uint8 j = 1; j <= 7; j++) {
                // Start at 1, go through 7
                // Access the 1-based mapping directly
                if (week[i].day[j].isCompleted) {
                    completedDays++;
                }
            }
        }

        if (totalDays > 0) {
            // Calculation remains correct for 2 decimal places
            percentage = (uint256(completedDays) * 10000) / uint256(totalDays);
        } else {
            percentage = 0;
        }
        // Return values are fine
    }
}