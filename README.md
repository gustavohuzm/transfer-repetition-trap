# TransferWithExactRepetitionTrap

It is designed to detect suspicious behavior involving **repeated token transfers** to the same recipient with the **exact same amount**, which may indicate automated bots, wash trading, or malicious token distribution.

---

## 🧠 Use Case

### 🎯 Use-cases

---

### 📌 Summary
This trap detects **repeated transfers** to the **same address** with the **same token amount** in a single batch of transaction logs. This pattern often signals potential exploit attempts such as:
- Bot-driven airdrop abuse  
- Wash trading to manipulate volume  
- Faulty or suspicious token distribution systems

---

### ✅ Trigger Conditions
The trap **responds with `true`** when:
- There are **two or more transfers** in the same batch where:
  - The **recipient address is the same**, and  
  - The **transfer amount is the same**.

---

### 🛑 No Response If:
- There are no transfer logs.
- Only one transfer exists (no pair to compare).
- No repeated transfer to the same address with the same amount is found.
- The transfer log length exceeds 100 (to prevent excessive computation).

---

## 🧪 Supported Event Format

```solidity
struct TransferEvent {
    address from;
    address to;
    uint256 amount;
}
```

---

## ⚙️ Implementation Details
```
collect()
```
Returns a static encoded value (true). No on-chain data is collected or needed.

```
shouldRespond(bytes[] calldata _data)
```
Logic:

- Expects _data[1] to be an encoded array of TransferEvent[].

- Iterates through the events and checks for any repeated (to, amount) pairs.

- If found, returns (true, "Repeated transfers detected").

- Otherwise returns (false, "").

---

## 🧾 Real-world Scenarios
1. Airdrop Bot Abuse
Bots sending multiple identical transfers to a single address to game the reward distribution system.

2. Wash Trading on Illiquid Tokens
An attacker fakes transaction volume by self-trading with the same transfer pattern repeatedly.

3. Malicious or Lazy Token Distribution
A project distributes tokens to users without randomness or protection, creating potential abuse vectors.

---