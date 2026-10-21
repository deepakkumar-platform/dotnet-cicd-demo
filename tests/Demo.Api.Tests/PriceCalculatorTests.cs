using Demo.Api;

namespace Demo.Api.Tests;

public class PriceCalculatorTests
{
    private readonly PriceCalculator _calc = new();

    [Fact]
    public void Total_NoDiscount_UnderTenItems() => Assert.Equal(90m, _calc.Total(10m, 9));

    [Fact]
    public void Total_TenPercentDiscount_AtTenItems() => Assert.Equal(90m, _calc.Total(10m, 10));

    [Fact]
    public void Total_ZeroQuantity_IsZero() => Assert.Equal(0m, _calc.Total(10m, 0));

    [Fact]
    public void Total_NegativePrice_Throws() =>
        Assert.Throws<ArgumentOutOfRangeException>(() => _calc.Total(-1m, 1));
}
