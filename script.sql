CREATE DATABASE PawnShopDB;
GO

USE PawnShopDB;
GO

/* =========================
   TABLE: CUSTOMER
========================= */
CREATE TABLE CUSTOMER (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Phone VARCHAR(20),
    Address NVARCHAR(255),
    CCCD VARCHAR(20),
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

/* =========================
   TABLE: EMPLOYEE
========================= */
CREATE TABLE EMPLOYEE (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100),
    Phone VARCHAR(20),
    Position NVARCHAR(100)
);
GO

/* =========================
   TABLE: CONTRACT
========================= */
CREATE TABLE CONTRACT (
    ContractID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    LoanAmount DECIMAL(18,2) NOT NULL,
    StartDate DATE DEFAULT GETDATE(),
    Deadline1 DATE NOT NULL,
    Deadline2 DATE NOT NULL,
    Status NVARCHAR(50) DEFAULT N'Đang vay',
    CreatedAt DATETIME DEFAULT GETDATE(),
    Note NVARCHAR(255),

    CONSTRAINT FK_CONTRACT_CUSTOMER
    FOREIGN KEY (CustomerID)
    REFERENCES CUSTOMER(CustomerID)
);
GO

/* =========================
   TABLE: ASSET
========================= */
CREATE TABLE ASSET (
    AssetID INT IDENTITY(1,1) PRIMARY KEY,
    AssetName NVARCHAR(100),
    AssetType NVARCHAR(100),
    Description NVARCHAR(255),
    EstimatedValue DECIMAL(18,2),
    AssetStatus NVARCHAR(50) DEFAULT N'Đang cầm cố'
);
GO

/* =========================
   TABLE: CONTRACT_ASSET
========================= */
CREATE TABLE CONTRACT_ASSET (
    ContractAssetID INT IDENTITY(1,1) PRIMARY KEY,
    ContractID INT,
    AssetID INT,
    ValuationAmount DECIMAL(18,2),
    IsReturned BIT DEFAULT 0,
    ReturnDate DATETIME,
    Note NVARCHAR(255),

    CONSTRAINT FK_CA_CONTRACT
    FOREIGN KEY (ContractID)
    REFERENCES CONTRACT(ContractID),

    CONSTRAINT FK_CA_ASSET
    FOREIGN KEY (AssetID)
    REFERENCES ASSET(AssetID)
);
GO

/* =========================
   TABLE: MONEY_TRANSACTION
========================= */
CREATE TABLE MONEY_TRANSACTION (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    ContractID INT,
    TransactionDate DATETIME DEFAULT GETDATE(),
    PrincipalChange DECIMAL(18,2),
    InterestChange DECIMAL(18,2),
    TotalDebtAfter DECIMAL(18,2),
    Description NVARCHAR(255),

    CONSTRAINT FK_MT_CONTRACT
    FOREIGN KEY (ContractID)
    REFERENCES CONTRACT(ContractID)
);
GO

/* =========================
   TABLE: PAYMENT_LOG
========================= */
CREATE TABLE PAYMENT_LOG (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    ContractID INT,
    PaymentDate DATETIME DEFAULT GETDATE(),
    AmountPaid DECIMAL(18,2),
    EmployeeID INT,
    RemainingDebt DECIMAL(18,2),
    Note NVARCHAR(255),

    CONSTRAINT FK_PAYMENT_CONTRACT
    FOREIGN KEY (ContractID)
    REFERENCES CONTRACT(ContractID),

    CONSTRAINT FK_PAYMENT_EMPLOYEE
    FOREIGN KEY (EmployeeID)
    REFERENCES EMPLOYEE(EmployeeID)
);
GO

/* =========================
   TABLE: CONTRACT_STATUS_HISTORY
========================= */
CREATE TABLE CONTRACT_STATUS_HISTORY (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    ContractID INT,
    OldStatus NVARCHAR(50),
    NewStatus NVARCHAR(50),
    ChangeDate DATETIME DEFAULT GETDATE(),
    EmployeeID INT,
    Note NVARCHAR(255),

    CONSTRAINT FK_HISTORY_CONTRACT
    FOREIGN KEY (ContractID)
    REFERENCES CONTRACT(ContractID),

    CONSTRAINT FK_HISTORY_EMPLOYEE
    FOREIGN KEY (EmployeeID)
    REFERENCES EMPLOYEE(EmployeeID)
);
GO

/* =========================
   TABLE: ASSET_LIQUIDATION
========================= */
CREATE TABLE ASSET_LIQUIDATION (
    LiquidationID INT IDENTITY(1,1) PRIMARY KEY,
    AssetID INT,
    LiquidationDate DATETIME DEFAULT GETDATE(),
    SellPrice DECIMAL(18,2),
    Buyer NVARCHAR(100),
    Note NVARCHAR(255),

    CONSTRAINT FK_LIQUIDATION_ASSET
    FOREIGN KEY (AssetID)
    REFERENCES ASSET(AssetID)
);
GO

/* =========================
   FUNCTION: fn_CalcMoneyContract
========================= */
CREATE FUNCTION fn_CalcMoneyContract
(
    @ContractID INT,
    @TargetDate DATE
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @LoanAmount DECIMAL(18,2);
    DECLARE @StartDate DATE;
    DECLARE @Deadline1 DATE;

    DECLARE @SimpleInterest DECIMAL(18,2);
    DECLARE @Total DECIMAL(18,2);

    DECLARE @SimpleDays INT;
    DECLARE @CompoundDays INT;

    SELECT
        @LoanAmount = LoanAmount,
        @StartDate = StartDate,
        @Deadline1 = Deadline1
    FROM CONTRACT
    WHERE ContractID = @ContractID;

    IF @TargetDate <= @Deadline1
    BEGIN
        SET @SimpleDays = DATEDIFF(DAY, @StartDate, @TargetDate);

        SET @SimpleInterest =
            (@LoanAmount / 1000000.0)
            * 5000
            * @SimpleDays;

        SET @Total = @LoanAmount + @SimpleInterest;
    END
    ELSE
    BEGIN
        SET @SimpleDays = DATEDIFF(DAY, @StartDate, @Deadline1);

        SET @SimpleInterest =
            (@LoanAmount / 1000000.0)
            * 5000
            * @SimpleDays;

        DECLARE @Base DECIMAL(18,2);

        SET @Base = @LoanAmount + @SimpleInterest;

        SET @CompoundDays = DATEDIFF(
            DAY,
            @Deadline1,
            @TargetDate
        );

        SET @Total = @Base * POWER(1.005, @CompoundDays);
    END

    RETURN @Total;
END;
GO

/* =========================
   FUNCTION: fn_CalcMoneyTransaction
========================= */
CREATE FUNCTION fn_CalcMoneyTransaction
(
    @TransactionID INT,
    @TargetDate DATE
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @ContractID INT;

    SELECT @ContractID = ContractID
    FROM MONEY_TRANSACTION
    WHERE TransactionID = @TransactionID;

    RETURN dbo.fn_CalcMoneyContract(
        @ContractID,
        @TargetDate
    );
END;
GO

/* =========================
   PROCEDURE: CREATE CONTRACT
========================= */
CREATE PROCEDURE sp_CreateContract
    @CustomerID INT,
    @LoanAmount DECIMAL(18,2),
    @Deadline1 DATE,
    @Deadline2 DATE,
    @Note NVARCHAR(255)
AS
BEGIN
    INSERT INTO CONTRACT(
        CustomerID,
        LoanAmount,
        StartDate,
        Deadline1,
        Deadline2,
        Status,
        Note
    )
    VALUES(
        @CustomerID,
        @LoanAmount,
        GETDATE(),
        @Deadline1,
        @Deadline2,
        N'Đang vay',
        @Note
    );
END;
GO

/* =========================
   PROCEDURE: PAY DEBT
========================= */
CREATE PROCEDURE sp_PayDebt
    @ContractID INT,
    @AmountPaid DECIMAL(18,2),
    @EmployeeID INT,
    @Note NVARCHAR(255)
AS
BEGIN
    DECLARE @CurrentDebt DECIMAL(18,2);
    DECLARE @RemainingDebt DECIMAL(18,2);
    DECLARE @Status NVARCHAR(50);

    SELECT @Status = Status
    FROM CONTRACT
    WHERE ContractID = @ContractID;

    IF @Status = N'Đã thanh lý tài sản'
    BEGIN
        PRINT N'Tài sản đã bị thanh lý. Không thể thu tiền.';
        RETURN;
    END

    SET @CurrentDebt = dbo.fn_CalcMoneyContract(
        @ContractID,
        GETDATE()
    );

    SET @RemainingDebt =
        @CurrentDebt - @AmountPaid;

    INSERT INTO PAYMENT_LOG(
        ContractID,
        AmountPaid,
        EmployeeID,
        RemainingDebt,
        Note
    )
    VALUES(
        @ContractID,
        @AmountPaid,
        @EmployeeID,
        @RemainingDebt,
        @Note
    );

    IF @RemainingDebt <= 0
    BEGIN
        UPDATE CONTRACT
        SET Status = N'Đã thanh toán'
        WHERE ContractID = @ContractID;

        UPDATE ASSET
        SET AssetStatus = N'Đã trả khách'
        WHERE AssetID IN (
            SELECT AssetID
            FROM CONTRACT_ASSET
            WHERE ContractID = @ContractID
        );
    END
    ELSE
    BEGIN
        UPDATE CONTRACT
        SET Status = N'Đang trả góp'
        WHERE ContractID = @ContractID;
    END
END;
GO

/* =========================
   PROCEDURE: EXTEND CONTRACT
========================= */
CREATE PROCEDURE sp_ExtendContract
    @ContractID INT,
    @NewDeadline1 DATE,
    @NewDeadline2 DATE
AS
BEGIN
    UPDATE CONTRACT
    SET Deadline1 = @NewDeadline1,
        Deadline2 = @NewDeadline2,
        Status = N'Đang vay'
    WHERE ContractID = @ContractID;
END;
GO

/* =========================
   TRIGGER: BAD DEBT
========================= */
CREATE TRIGGER trg_UpdateBadDebt
ON CONTRACT
AFTER UPDATE
AS
BEGIN
    UPDATE CONTRACT
    SET Status = N'Quá hạn (nợ xấu)'
    WHERE ContractID IN (
        SELECT ContractID
        FROM inserted
    )
    AND GETDATE() > Deadline1
    AND Status = N'Đang vay';
END;
GO

/* =========================
   TRIGGER: READY TO LIQUIDATE
========================= */
CREATE TRIGGER trg_ReadyToLiquidate
ON CONTRACT
AFTER UPDATE
AS
BEGIN
    UPDATE ASSET
    SET AssetStatus = N'Sẵn sàng thanh lý'
    WHERE AssetID IN (
        SELECT CA.AssetID
        FROM CONTRACT_ASSET CA
        JOIN CONTRACT C
        ON CA.ContractID = C.ContractID
        WHERE GETDATE() > C.Deadline2
        AND C.Status = N'Quá hạn (nợ xấu)'
    );
END;
GO

/* =========================
   TRIGGER: SOLD ASSET
========================= */
CREATE TRIGGER trg_SoldAsset
ON CONTRACT
AFTER UPDATE
AS
BEGIN
    UPDATE ASSET
    SET AssetStatus = N'Đã bán thanh lý'
    WHERE AssetID IN (
        SELECT CA.AssetID
        FROM CONTRACT_ASSET CA
        JOIN inserted i
        ON CA.ContractID = i.ContractID
        WHERE i.Status = N'Đã thanh lý tài sản'
    );
END;
GO

/* =========================
   VIEW: BAD DEBT LIST
========================= */
CREATE VIEW vw_BadDebtList
AS
SELECT
    C.FullName,
    C.Phone,
    CT.ContractID,
    CT.LoanAmount,

    DATEDIFF(
        DAY,
        CT.Deadline1,
        GETDATE()
    ) AS OverdueDays,

    dbo.fn_CalcMoneyContract(
        CT.ContractID,
        GETDATE()
    ) AS CurrentDebt,

    dbo.fn_CalcMoneyContract(
        CT.ContractID,
        DATEADD(MONTH, 1, GETDATE())
    ) AS DebtAfterOneMonth

FROM CUSTOMER C
JOIN CONTRACT CT
ON C.CustomerID = CT.CustomerID

WHERE GETDATE() > CT.Deadline1
AND CT.Status <> N'Đã thanh toán';
GO

/* =========================
   SAMPLE DATA
========================= */
INSERT INTO CUSTOMER(
    FullName,
    Phone,
    Address,
    CCCD
)
VALUES
(N'Nguyễn Văn A', '0911111111', N'Hà Nội', '001'),
(N'Trần Văn B', '0922222222', N'Thái Nguyên', '002');
GO

INSERT INTO EMPLOYEE(
    FullName,
    Phone,
    Position
)
VALUES
(N'Lê Văn C', '0933333333', N'Nhân viên');
GO

INSERT INTO CONTRACT(
    CustomerID,
    LoanAmount,
    StartDate,
    Deadline1,
    Deadline2,
    Status,
    Note
)
VALUES
(
    1,
    10000000,
    GETDATE(),
    DATEADD(DAY,10,GETDATE()),
    DATEADD(DAY,20,GETDATE()),
    N'Đang vay',
    N'Hợp đồng cầm iPhone'
);
GO

INSERT INTO ASSET(
    AssetName,
    AssetType,
    Description,
    EstimatedValue,
    AssetStatus
)
VALUES
(
    N'iPhone 15 Pro Max',
    N'Điện thoại',
    N'Màu Titan',
    15000000,
    N'Đang cầm cố'
);
GO

INSERT INTO CONTRACT_ASSET(
    ContractID,
    AssetID,
    ValuationAmount,
    Note
)
VALUES
(
    1,
    1,
    15000000,
    N'Tài sản thế chấp chính'
);
GO

INSERT INTO MONEY_TRANSACTION(
    ContractID,
    TransactionDate,
    PrincipalChange,
    InterestChange,
    TotalDebtAfter,
    Description
)
VALUES
(
    1,
    GETDATE(),
    10000000,
    0,
    10000000,
    N'Khởi tạo hợp đồng vay'
);
GO

/* =========================
   TEST FUNCTION
========================= */
SELECT dbo.fn_CalcMoneyContract(1, GETDATE())
AS CurrentDebt;
GO

/* =========================
   TEST VIEW
========================= */
SELECT *
FROM vw_BadDebtList;
GO