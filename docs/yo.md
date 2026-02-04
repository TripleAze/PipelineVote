# Multi-Cloud AI Voice Transaction Demo  
## High-Level Architecture & Flow (MVP)

> **Purpose**  
This document provides a high-level architectural view of a multi-cloud demo system designed to showcase AI-assisted voice-based transactions over telephony.  
Details are intentionally abstracted for confidentiality.

---

## 1. Architecture Overview

The system follows a **multi-cloud, event-driven architecture**:

- **Linode** hosts the telephony and identity plane
- **AWS** hosts application logic, AI services, security, and orchestration
- Communication is handled over secure HTTPS APIs
- Core services are stateless and loosely coupled

---

## 2. Logical Architecture Diagram

```mermaid
flowchart LR

%% ===== USERS =====
U1[Caller A<br/>Mobile Phone]
U2[Caller B<br/>Mobile Phone]

%% ===== TELCO =====
PSTN[PSTN Network]
SIP[SIP Trunk Provider]

U1 --> PSTN
U2 --> PSTN
PSTN --> SIP

%% ===== LINODE =====
subgraph LINODE["Linode Cloud<br/>(Telephony Plane)"]
    PBX[3CX PBX<br/>Call Control & Media]
    AD[Active Directory<br/>Identity Services]
end

SIP --> PBX
AD <-- LDAP / Sync --> PBX

%% ===== API BRIDGE =====
PBX -->|Secure HTTPS Events| APIGW

%% ===== AWS =====
subgraph AWS["AWS Cloud<br/>(Application & Intelligence Plane)"]

    subgraph VPC["VPC"]
        APIGW[API Gateway]

        EC2[EC2 Orchestrator<br/>Call Logic & State]

        SQS[SQS Queue<br/>Async Events + DLQ]

        LAMBDA[Lambda Functions<br/>OTP, Transactions, Receipts]

        DDB[DynamoDB<br/>Ledger & Session State]

        SNS[SNS<br/>SMS OTP & Notifications]

        AI[AI Voice Stack<br/>ASR · NLU · TTS]

        CW[CloudWatch<br/>Logs & Metrics]
    end
end

%% ===== FLOWS =====
APIGW --> EC2
APIGW --> SQS

SQS --> LAMBDA
LAMBDA --> DDB
LAMBDA --> SNS
LAMBDA --> AI

EC2 -->|Call Control API| PBX

SNS --> U1
SNS --> U2

EC2 --> CW
LAMBDA --> CW
APIGW --> CW
