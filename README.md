# 🆔 Verifiable Refugee Identity System (RefugeeID)

> A self-sovereign identity system for refugees and displaced persons built on Stacks blockchain

## 🌟 Overview

RefugeeID provides refugees and displaced persons with a **digital, portable, and verifiable identity** that they own and control. This blockchain-based system enables access to aid, services, and opportunities without requiring traditional documentation.

## ✨ Key Features

### 🏛️ Core Identity Management
- **Self-Registration**: Refugees can register their own identity with biometric verification
- **Verification System**: Authorized organizations can verify identity claims
- **Portable Records**: Identity data follows the person across borders and jurisdictions
- **Privacy Control**: Users control who accesses their data and for what purpose

### 📜 Credential System  
- **Digital Credentials**: Issue and verify educational, professional, and medical credentials
- **Expiration Management**: Automatic handling of credential validity periods
- **Revocation Support**: Ability to revoke compromised or invalid credentials

### 🤝 Aid Distribution Tracking
- **Transparent Records**: All aid disbursements are recorded on-chain
- **Duplicate Prevention**: Prevents double-spending of aid resources
- **Impact Measurement**: Track total aid distributed and effectiveness

### 🔐 Access Control & Privacy
- **Granular Permissions**: Users grant specific access rights to service providers
- **Consent Logging**: All data access is logged with explicit consent
- **Emergency Contacts**: Designated contacts for crisis situations

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation
```bash
git clone <repository-url>
cd Verifiable-Refugee-Identity-System
clarinet check
```

## 🛠️ Usage Guide

### 1. 📝 Register an Identity
```clarity
(contract-call? .RefugeeID register-identity 
  "John Doe"
  "1990-01-15"
  "Damascus, Syria"
  "Syrian"
  "biometric-hash-64-chars"
)
```

### 2. ✅ Verify Identity (Authorized Verifiers Only)
```clarity
(contract-call? .RefugeeID verify-identity 
  'SP1IDENTITY...
  u3  ;; verification level 1-5
)
```

### 3. 🎓 Issue Credentials
```clarity
(contract-call? .RefugeeID issue-credential
  'SP1IDENTITY...
  "education-diploma"
  u105000  ;; expiry block height
  "credential-data-hash"
)
```

### 4. 💰 Record Aid Disbursement
```clarity
(contract-call? .RefugeeID record-aid-disbursement
  'SP1RECIPIENT...
  "AID-2024-001"
  u1000000  ;; amount in microSTX
  "food-assistance"
  "Camp Alpha, Jordan"
)
```

### 5. 🔑 Grant Access Permissions
```clarity
(contract-call? .RefugeeID grant-access-permission
  'SP1SERVICE...
  (list "basic-info" "education" "medical")
  u110000  ;; expires at block height
)
```

## 📊 Smart Contract Functions

### Public Functions
| Function | Purpose | Access |
|----------|---------|--------|
| `register-identity` | Register new refugee identity | Anyone (with fee) |
| `register-verifier` | Add authorized verifier | Contract owner |
| `verify-identity` | Verify identity claims | Authorized verifiers |
| `issue-credential` | Issue digital credentials | Authorized verifiers |
| `record-aid-disbursement` | Log aid distribution | Aid providers |
| `grant-access-permission` | Grant data access | Identity owner |
| `revoke-access-permission` | Revoke data access | Identity owner |
| `log-data-sharing` | Log data access events | Verifiers/Identity owner |
| `update-identity-status` | Update identity status | Owner/Identity holder |
| `set-emergency-contact` | Set emergency contact | Identity owner |

### Read-Only Functions
| Function | Purpose |
|----------|---------|
| `get-identity` | Retrieve identity information |
| `get-verifier` | Get verifier details |
| `get-credential` | Retrieve specific credential |
| `get-aid-record` | Get aid distribution record |
| `is-identity-verified` | Check verification status |
| `has-valid-credential` | Validate credential status |
| `get-contract-stats` | Get contract statistics |

## 🔒 Security Features

### 💵 Economic Security
- **Registration Fee**: Prevents spam registrations (default: 1 STX)
- **Verification Fee**: Covers verification costs (default: 0.5 STX)
- **Fee Adjustable**: Contract owner can update fees

### 🛡️ Access Control
- **Owner Privileges**: Contract management functions
- **Verifier Authorization**: Only authorized entities can verify
- **Self-Sovereign Control**: Users control their own data access

### 🔍 Audit Trail
- **Immutable Records**: All actions recorded on blockchain
- **Timestamp Tracking**: Block height recorded for all operations
- **Consent Logging**: Explicit consent required for data sharing

## 🎯 Use Cases

### 🏥 Healthcare Access
- Store medical records and vaccination certificates
- Enable healthcare providers to verify medical history
- Track medical aid distribution

### 🎓 Education & Employment
- Verify educational credentials and professional qualifications
- Enable skill-based matching for employment opportunities
- Portable academic records across jurisdictions

### 🏛️ Government Services
- Access social services and benefits
- Voter registration and civic participation
- Legal identity establishment

### 💰 Financial Services
- Identity verification for banking and microfinance
- Credit history establishment
- Remittance recipient verification

## 📈 Contract Statistics

Track system-wide metrics:
- Total registered identities
- Total aid disbursed
- Current fee structure
- Network adoption metrics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `clarinet check` to validate
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🆘 Support

For questions, issues, or feature requests:
- Open an issue on GitHub
- Contact the development team
- Check the documentation

---

**Built with ❤️ for refugees and displaced persons worldwide**
