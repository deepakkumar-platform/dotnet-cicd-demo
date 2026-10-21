namespace Demo.Api;

public class PriceCalculator
{
    // 10% discount on orders of 10 items or more
    public decimal Total(decimal unitPrice, int quantity)
    {
        if (unitPrice < 0) throw new ArgumentOutOfRangeException(nameof(unitPrice));
        if (quantity < 0) throw new ArgumentOutOfRangeException(nameof(quantity));

        var total = unitPrice * quantity;
        return quantity >= 10 ? total * 0.9m : total;
    }
}
