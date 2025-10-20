
import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;
const address3 = accounts.get("wallet_3")!;
const address4 = accounts.get("wallet_4")!;

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

describe("example tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  // it("shows an example", () => {
  //   const { result } = simnet.callReadOnlyFn("counter", "get-counter", [], address1);
  //   expect(result).toBeUint(0);
  // });
});

describe("Service Provider Rating System", () => {
  it("allows verified identity to rate provider", () => {
    // Register rater identity
    let response = simnet.callPublicFn(
      "RefugeeID",
      "register-identity",
      [
        Cl.stringAscii("John Doe"),
        Cl.stringAscii("1990-01-15"),
        Cl.stringAscii("Damascus"),
        Cl.stringAscii("Syrian"),
        Cl.stringAscii("a".repeat(64)),
      ],
      address1
    );
    expect(response.result).toBeOk(Cl.principal(address1));

    // Verify rater identity
simnet.callPublicFn("RefugeeID", "register-verifier", [Cl.principal(address2), Cl.stringAscii("Verifier Org"), Cl.stringAscii("Verification Organization")], deployer);
    response = simnet.callPublicFn(
      "RefugeeID",
      "verify-identity",
      [Cl.principal(address1), Cl.uint(3)],
      address2
    );
    expect(response.result).toBeOk(Cl.principal(address1));

    // Register provider identity (unverified is OK for provider)
    response = simnet.callPublicFn(
      "RefugeeID",
      "register-identity",
      [
        Cl.stringAscii("Aid Organization"),
        Cl.stringAscii("2000-01-01"),
        Cl.stringAscii("Geneva"),
        Cl.stringAscii("International"),
        Cl.stringAscii("b".repeat(64)),
      ],
      address3
    );
    expect(response.result).toBeOk(Cl.principal(address3));

    // Rate service provider
    response = simnet.callPublicFn(
      "RefugeeID",
      "rate-service-provider",
      [
        Cl.principal(address3),
        Cl.uint(5),
        Cl.stringAscii("Excellent service"),
      ],
      address1
    );
    expect(response.result).toBeOk(Cl.bool(true));

    // Retrieve rating
    const getRatingResponse = simnet.callReadOnlyFn(
      "RefugeeID",
      "get-provider-rating",
      [Cl.principal(address3), Cl.principal(address1)],
      address1
    );
    const rating = getRatingResponse.result;
    expect(rating).toContain("rating");
  });

  it("prevents invalid ratings outside 1-5 range", () => {
    // Register and verify rater
    simnet.callPublicFn(
      "RefugeeID",
      "register-identity",
      [
        Cl.stringAscii("Rater Two"),
        Cl.stringAscii("1985-05-20"),
        Cl.stringAscii("Istanbul"),
        Cl.stringAscii("Turkish"),
        Cl.stringAscii("c".repeat(64)),
      ],
      address2
    );

simnet.callPublicFn("RefugeeID", "register-verifier", [Cl.principal(address2), Cl.stringAscii("Verifier"), Cl.stringAscii("Verification")], deployer);
    simnet.callPublicFn(
      "RefugeeID",
      "verify-identity",
      [Cl.principal(address2), Cl.uint(2)],
      address2
    );

    // Register provider
    simnet.callPublicFn(
      "RefugeeID",
      "register-identity",
      [
        Cl.stringAscii("Provider Two"),
        Cl.stringAscii("2001-01-01"),
        Cl.stringAscii("Berlin"),
        Cl.stringAscii("German"),
        Cl.stringAscii("d".repeat(64)),
      ],
      address4
    );

    // Try to submit rating of 6 (should fail)
    let response = simnet.callPublicFn(
      "RefugeeID",
      "rate-service-provider",
      [
        Cl.principal(address4),
        Cl.uint(6),
        Cl.stringAscii("Invalid rating"),
      ],
      address2
    );
    expect(response.result).toBeErr(Cl.uint(110)); // ERR_INVALID_RATING

    // Try to submit rating of 0 (should fail)
    response = simnet.callPublicFn(
      "RefugeeID",
      "rate-service-provider",
      [
        Cl.principal(address4),
        Cl.uint(0),
        Cl.stringAscii("Invalid rating"),
      ],
      address2
    );
    expect(response.result).toBeErr(Cl.uint(110)); // ERR_INVALID_RATING
  });

  it("prevents duplicate ratings from same user", () => {
    // Setup: Register and verify rater
    simnet.callPublicFn(
      "RefugeeID",
      "register-identity",
      [
        Cl.stringAscii("Unique Rater"),
        Cl.stringAscii("1992-03-10"),
        Cl.stringAscii("Cairo"),
        Cl.stringAscii("Egyptian"),
        Cl.stringAscii("e".repeat(64)),
      ],
      address1
    );
simnet.callPublicFn("RefugeeID", "register-verifier", [Cl.principal(address1), Cl.stringAscii("Verifier"), Cl.stringAscii("Org")], deployer);
    simnet.callPublicFn(
      "RefugeeID",
      "verify-identity",
      [Cl.principal(address1), Cl.uint(1)],
      address1
    );

    // Register provider
    simnet.callPublicFn(
      "RefugeeID",
      "register-identity",
      [
        Cl.stringAscii("Unique Provider"),
        Cl.stringAscii("2002-01-01"),
        Cl.stringAscii("Dubai"),
        Cl.stringAscii("UAE"),
        Cl.stringAscii("f".repeat(64)),
      ],
      address2
    );

    // First rating (should succeed)
    let response = simnet.callPublicFn(
      "RefugeeID",
      "rate-service-provider",
      [
        Cl.principal(address2),
        Cl.uint(4),
        Cl.stringAscii("Good service"),
      ],
      address1
    );
    expect(response.result).toBeOk(Cl.bool(true));

    // Second rating from same user (should fail)
    response = simnet.callPublicFn(
      "RefugeeID",
      "rate-service-provider",
      [
        Cl.principal(address2),
        Cl.uint(3),
        Cl.stringAscii("Different feedback"),
      ],
      address1
    );
    expect(response.result).toBeErr(Cl.uint(112)); // ERR_DUPLICATE_RATING
  });

  it("allows updating existing ratings", () => {
    // Setup: Register and verify rater
    simnet.callPublicFn(
      "RefugeeID",
      "register-identity",
      [
        Cl.stringAscii("Update Rater"),
        Cl.stringAscii("1988-12-25"),
        Cl.stringAscii("Bangkok"),
        Cl.stringAscii("Thai"),
        Cl.stringAscii("g".repeat(64)),
      ],
      address1
    );
simnet.callPublicFn("RefugeeID", "register-verifier", [Cl.principal(address1), Cl.stringAscii("Verif"), Cl.stringAscii("Org")], deployer);
    simnet.callPublicFn(
      "RefugeeID",
      "verify-identity",
      [Cl.principal(address1), Cl.uint(2)],
      address1
    );

    // Register provider
    simnet.callPublicFn(
      "RefugeeID",
      "register-identity",
      [
        Cl.stringAscii("Update Provider"),
        Cl.stringAscii("2003-01-01"),
        Cl.stringAscii("Tokyo"),
        Cl.stringAscii("Japanese"),
        Cl.stringAscii("h".repeat(64)),
      ],
      address2
    );

    // Submit initial rating
    let response = simnet.callPublicFn(
      "RefugeeID",
      "rate-service-provider",
      [
        Cl.principal(address2),
        Cl.uint(2),
        Cl.stringAscii("Needs improvement"),
      ],
      address1
    );
    expect(response.result).toBeOk(Cl.bool(true));

    // Update rating
    response = simnet.callPublicFn(
      "RefugeeID",
      "update-provider-rating",
      [
        Cl.principal(address2),
        Cl.uint(5),
        Cl.stringAscii("Much better now"),
      ],
      address1
    );
    expect(response.result).toBeOk(Cl.bool(true));

    // Verify updated rating
    const getRatingResponse = simnet.callReadOnlyFn(
      "RefugeeID",
      "get-provider-rating",
      [Cl.principal(address2), Cl.principal(address1)],
      address1
    );
    expect(getRatingResponse.result).toContain("5"); // Updated rating should be 5
  });
});
