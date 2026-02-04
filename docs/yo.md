flowchart LR

%% ========= USER & TELECOM =========
A[Caller A<br/>Mobile Phone]
B[Caller B<br/>Mobile Phone]

PSTN[PSTN Network]
SIP[SIP Trunk Provider]

A --> PSTN
B --> PSTN
PSTN --> SIP

%% ========= LINODE / TELEPHONY PLANE =========
subgraph LINODE["Linode Cloud (Telephony Plane)"]
    PBX[3CX PBX<br/>Call Control & Media]
    AD[Active Directory<br/>User Identity]
end

SIP --> PBX
AD <-- LDAP Sync --> PBX

%% ========= SECURE API BRIDGE =========
PBX -->|HTTPS Events & Control| APIGW

%% ========= AWS CLOUD =========
subgraph AWS["AWS Cloud (Application & Intelligence Plane)"]

    subgraph NET["VPC"]
        APIGW[API Gateway]

        EC2[EC2 t3.small<br/>Call Orchestrator<br/>+ Elastic IP]

        SQS[SQS Queue<br/>+ DLQ]

        LAMBDA[Lambda Functions<br/>OTP / Transaction / Receipt]

        DDB[DynamoDB<br/>Ledger + OTP + Sessions]

        SNS[AWS SNS<br/>OTP & Receipt SMS]

        AI[AI Voice Stack<br/>ASR / LID / NLU / TTS]

        CW[CloudWatch<br/>Logs & Metrics]
    end

end

%% ========= INTERNAL FLOWS =========
APIGW --> EC2
APIGW --> SQS

SQS --> LAMBDA
LAMBDA --> DDB
LAMBDA --> SNS
LAMBDA --> AI

EC2 -->|Call Control API| PBX

%% ========= NOTIFICATIONS =========
SNS --> A
SNS --> B

%% ========= OBSERVABILITY =========
EC2 --> CW
LAMBDA --> CW
APIGW --> CW
