# Interview Questions - Lesson 006: IAM Security, Resource Policies, & API Keys

**Q: If you need to allow a third-party AWS account to invoke models hosted in your account, how would you design the security architecture?**

*Answer*:

I would configure a cross-account IAM Role:

1. In the hosting account, create an IAM Role (e.g. `BedrockCrossAccountRole`) containing a trust relationship policy that allows the third-party account ID (`sts:AssumeRole`) to assume the role.
2. Attach a least-privilege policy to this role permitting only `bedrock:Converse` on approved Model ARNs.
3. The third-party account can then call `AssumeRole` to fetch temporary credentials, using those to sign requests and communicate securely with our Bedrock endpoints.

---
