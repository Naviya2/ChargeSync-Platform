using Infrastructure.Authentication;

namespace UnitTests.Authentication;

public class BcryptPasswordHasherTests
{
    private readonly BcryptPasswordHasher _hasher = new();

    [Fact]
    public void Hash_ProducesValueDifferentFromInput()
    {
        var hash = _hasher.Hash("correct horse battery staple");

        Assert.NotEqual("correct horse battery staple", hash);
        Assert.StartsWith("$2", hash);
    }

    [Fact]
    public void Hash_IsSaltedSoTwoHashesOfSamePasswordDiffer()
    {
        var first = _hasher.Hash("hunter2");
        var second = _hasher.Hash("hunter2");

        Assert.NotEqual(first, second);
    }

    [Fact]
    public void Verify_ReturnsTrueForCorrectPassword()
    {
        var hash = _hasher.Hash("s3cret-pass");

        Assert.True(_hasher.Verify("s3cret-pass", hash));
    }

    [Fact]
    public void Verify_ReturnsFalseForWrongPassword()
    {
        var hash = _hasher.Hash("s3cret-pass");

        Assert.False(_hasher.Verify("s3cret-pazz", hash));
    }
}
