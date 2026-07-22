package handles

import (
	"strings"

	"github.com/OpenListTeam/OpenList/v4/internal/conf"
	"github.com/OpenListTeam/OpenList/v4/internal/errs"
	"github.com/OpenListTeam/OpenList/v4/internal/model"
	"github.com/OpenListTeam/OpenList/v4/internal/offline_download/tool"
	"github.com/OpenListTeam/OpenList/v4/internal/op"
	"github.com/OpenListTeam/OpenList/v4/internal/task"
	"github.com/OpenListTeam/OpenList/v4/server/common"
	"github.com/gin-gonic/gin"
	"github.com/pkg/errors"
)

func OfflineDownloadTools(c *gin.Context) {
	tools := tool.Tools.Names()
	common.SuccessResp(c, tools)
}

type AddOfflineDownloadReq struct {
	Urls         []string `json:"urls"`
	Path         string   `json:"path"`
	Tool         string   `json:"tool"`
	DeletePolicy string   `json:"delete_policy"`
}

func AddOfflineDownload(c *gin.Context) {
	user := c.Request.Context().Value(conf.UserKey).(*model.User)
	if !user.CanAddOfflineDownloadTasks() {
		common.ErrorStrResp(c, "permission denied", 403)
		return
	}

	var req AddOfflineDownloadReq
	if err := c.ShouldBind(&req); err != nil {
		common.ErrorResp(c, err, 400)
		return
	}
	reqPath, err := user.JoinPath(req.Path)
	if err != nil {
		common.ErrorResp(c, err, 403)
		return
	}
	meta, err := op.GetNearestMeta(reqPath)
	if err != nil && !errors.Is(errors.Cause(err), errs.MetaNotFound) {
		common.ErrorResp(c, err, 500, true)
		return
	}
	if !common.CanWrite(user, meta, reqPath) {
		common.ErrorResp(c, errs.PermissionDenied, 403)
		return
	}
	var tasks []task.TaskExtensionInfo
	for _, url := range req.Urls {
		// Filter out empty lines and whitespace-only strings
		trimmedUrl := strings.TrimSpace(url)
		if trimmedUrl == "" {
			continue
		}

		t, err := tool.AddURL(c, &tool.AddURLArgs{
			URL:          trimmedUrl,
			DstDirPath:   reqPath,
			Tool:         req.Tool,
			DeletePolicy: tool.DeletePolicy(req.DeletePolicy),
		})
		if err != nil {
			common.ErrorResp(c, err, 500)
			return
		}
		if t != nil {
			tasks = append(tasks, t)
		}
	}
	common.SuccessResp(c, gin.H{
		"tasks": getTaskInfos(tasks),
	})
}
