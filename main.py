import polars as pl

df = pl.DataFrame([('foo', 'bar'), ('ham', 'spam')], schema=['A', 'B']).select(pl.col(0))
print(df)