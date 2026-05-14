# 📘 BÀI TẬP 03 - SQL SERVER

## 🔰 Thông tin sinh viên

* Họ tên: *[TRẦN TÙNG LÂM]*
* Mã sinh viên: **K235480106039**
* Môn học: Cơ sở dữ liệu
* Chủ đề: **Quản lý cầm đồ**

---

## 🧾 Mô tả bài toán

Đề tài xây dựng hệ thống quản lý cầm đồ phục vụ cho:

* Quản lý khách hàng.
* Quản lý hợp đồng vay tiền.
* Quản lý tài sản thế chấp.
* Tính lãi đơn và lãi kép.
* Quản lý trạng thái hợp đồng.
* Quản lý lịch sử trả nợ.
* Quản lý thanh lý tài sản.

Hệ thống được xây dựng bằng SQL Server với các thành phần:

* Database.
* Table.
* Function.
* Stored Procedure.
* Trigger.
* Query báo cáo.

---

# 2. Công nghệ sử dụng

| Thành phần       | Công nghệ                    |
| ---------------- | ---------------------------- |
| Hệ quản trị CSDL | SQL Server                   |
| Ngôn ngữ         | T-SQL                        |
| Công cụ thiết kế | Draw.io / SQL Server Diagram |
| IDE              | SQL Server Management Studio |
| Version Control  | GitHub                       |

---

# 3. Thiết kế cơ sở dữ liệu

## 3.1 Các bảng chính

### CUSTOMER

Lưu thông tin khách hàng.

### CONTRACT

Lưu thông tin hợp đồng vay.

### ASSET

Lưu thông tin tài sản thế chấp.

### CONTRACT_ASSET

Liên kết hợp đồng và tài sản.

### PAYMENT_LOG

Lưu lịch sử trả nợ.

### CONTRACT_LOG

Lưu lịch sử thay đổi trạng thái.

---

# 4. Sơ đồ ERD

## Ảnh ERD
![ERD](images/erd.png)

# 4.1 Script tạo bảng SQL

```sql
CREATE DATABASE PawnShopDB;
GO

USE PawnShopDB;
GO

CREATE TABLE CUSTOMER (
    CustomerID INT IDENTITY PRIMARY KEY,
    FullName NVARCHAR(100),
    Phone VARCHAR(20),
    Address NVARCHAR(255),
    CCCD VARCHAR(20),
    CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE CONTRACT (
    ContractID INT IDENTITY PRIMARY KEY,
    CustomerID INT,
    LoanAmount DECIMAL(18,2),
    StartDate DATE,
    Deadline1 DATE,
    Deadline2 DATE,
    Status NVARCHAR(50),
    CreatedAt DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (CustomerID)
    REFERENCES CUSTOMER(CustomerID)
);

CREATE TABLE ASSET (
    AssetID INT IDENTITY PRIMARY KEY,
    AssetName NVARCHAR(100),
    AssetType NVARCHAR(100),
    EstimatedValue DECIMAL(18,2),
    AssetStatus NVARCHAR(50)
);

CREATE TABLE CONTRACT_ASSET (
    ContractID INT,
    AssetID INT,

    PRIMARY KEY (ContractID, AssetID),

    FOREIGN KEY (ContractID)
    REFERENCES CONTRACT(ContractID),

    FOREIGN KEY (AssetID)
    REFERENCES ASSET(AssetID)
);

CREATE TABLE PAYMENT_LOG (
    PaymentID INT IDENTITY PRIMARY KEY,
    ContractID INT,
    PayDate DATETIME DEFAULT GETDATE(),
    AmountPaid DECIMAL(18,2),
    Collector NVARCHAR(100),
    RemainingDebt DECIMAL(18,2),

    FOREIGN KEY (ContractID)
    REFERENCES CONTRACT(ContractID)
);

CREATE TABLE CONTRACT_LOG (
    LogID INT IDENTITY PRIMARY KEY,
    ContractID INT,
    OldStatus NVARCHAR(50),
    NewStatus NVARCHAR(50),
    ChangedAt DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (ContractID)
    REFERENCES CONTRACT(ContractID)
);
```

## Ảnh tạo bảng SQL
![BSQL](images/BSQL.png)
