# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SqlDb.Repo.insert!(%SqlDb.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# If we're in dev, go ahead and put this in:
alias SqlDb.Accounts.User

if Mix.env() == :dev do
  # Create a user
  SqlDb.Repo.insert!(%User{email: "cinyc.s@gmail.com", hashed_password: "$argon2id$v=19$m=65536,t=8,p=2$MNmRrSGdMi5KuHs5S14bFQ$2m92QT1hF5bI30YOw9WlPdfdFu79+lhKL5yYalxzLZc", confirmed_at: ~N[2024-06-01 00:00:00Z]})
end
