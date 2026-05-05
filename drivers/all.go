package drivers

import (
	_ "github.com/OpenListTeam/OpenList/v4/drivers/115"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/115_open"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/123"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/123_open"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/ftp"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/local"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/openlist"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/openlist_share"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/pikpak"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/quark_open"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/quark_uc"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/quark_uc_tv"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/smb"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/thunder"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/thunder_browser"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/thunderx"
	_ "github.com/OpenListTeam/OpenList/v4/drivers/webdav"
)

// All do nothing,just for import
// same as _ import
func All() {
}
