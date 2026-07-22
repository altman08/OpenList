package drivers

import (
	_ "github.com/OpenListTeam/OpenList/v4/drivers/189pc"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/ftp"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/local"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/openlist"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/openlist_share"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/quark_open"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/quark_uc"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/quark_uc_tv"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/smb"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/webdav"
)

// All do nothing,just for import
// same as _ import
func All() {
}
