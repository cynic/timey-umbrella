use Amnesia

defdatabase Database do
  deftable PrefixMap, [:prefix, :user], type: :set, disc_copies: [node()] do
    @type t :: %PrefixMap{prefix: String.t(), user: integer()}
  end
end
