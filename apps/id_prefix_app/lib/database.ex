use Amnesia

defdatabase Database do
  @moduledoc false
  deftable PrefixMap, [:prefix, :user], type: :set, disc_only_copies: [node()] do
    @moduledoc false
    @type t :: %PrefixMap{prefix: String.t, user: integer}
  end
end
